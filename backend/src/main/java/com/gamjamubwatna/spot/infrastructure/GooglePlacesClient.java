package com.gamjamubwatna.spot.infrastructure;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.JsonNode;
import com.gamjamubwatna.spot.application.ExternalPlaceDetails;
import com.gamjamubwatna.spot.application.PlaceOpeningHours;
import java.math.BigDecimal;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicBoolean;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.util.UriUtils;

@Component
public class GooglePlacesClient {

    private static final Logger log = LoggerFactory.getLogger(GooglePlacesClient.class);

    private static final String TEXT_SEARCH_FIELD_MASK = String.join(",",
        "places.id",
        "places.displayName",
        "places.formattedAddress",
        "places.location"
    );
    private static final String DETAILS_FIELD_MASK = String.join(",",
        "id",
        "displayName",
        "formattedAddress",
        "location",
        "nationalPhoneNumber",
        "regularOpeningHours",
        "currentOpeningHours",
        "websiteUri",
        "rating",
        "photos"
    );
    private static final String PHOTO_FIELD_MASK = "photoUri";

    private final RestClient restClient;
    private final String baseUrl;
    private final String apiKey;
    private final String languageCode;
    private final String regionCode;
    private final int maxPhotoCount;
    private final AtomicBoolean missingApiKeyLogged = new AtomicBoolean();

    public GooglePlacesClient(
        RestClient.Builder restClientBuilder,
        @Value("${external.google-places.base-url}") String baseUrl,
        @Value("${external.google-places.api-key}") String apiKey,
        @Value("${external.google-places.language-code}") String languageCode,
        @Value("${external.google-places.region-code}") String regionCode,
        @Value("${external.google-places.max-photo-count}") int maxPhotoCount
    ) {
        this.restClient = restClientBuilder.build();
        this.baseUrl = stripTrailingSlash(baseUrl);
        this.apiKey = apiKey;
        this.languageCode = languageCode;
        this.regionCode = regionCode;
        this.maxPhotoCount = Math.max(1, maxPhotoCount);
    }

    public List<GooglePlaceSearchResult> searchText(String query) {
        if (!hasApiKey() || isBlank(query)) {
            return List.of();
        }

        GoogleTextSearchRequest request = new GoogleTextSearchRequest(query, languageCode, regionCode);
        JsonNode response;
        try {
            response = restClient.post()
                .uri("%s/places:searchText".formatted(baseUrl))
                .header("X-Goog-Api-Key", apiKey)
                .header("X-Goog-FieldMask", TEXT_SEARCH_FIELD_MASK)
                .contentType(MediaType.APPLICATION_JSON)
                .body(request)
                .retrieve()
                .body(JsonNode.class);
        } catch (RestClientResponseException exception) {
            throw apiException("text search", exception);
        }

        JsonNode places = response == null ? null : response.path("places");
        if (places == null || !places.isArray()) {
            return List.of();
        }

        List<GooglePlaceSearchResult> results = new ArrayList<>();
        for (JsonNode place : places) {
            results.add(new GooglePlaceSearchResult(
                readText(place, "id"),
                readText(place.path("displayName"), "text"),
                readText(place, "formattedAddress"),
                readDecimal(place.path("location"), "latitude"),
                readDecimal(place.path("location"), "longitude")
            ));
        }
        return results;
    }

    public Optional<ExternalPlaceDetails> findDetails(String placeId) {
        if (!hasApiKey() || isBlank(placeId)) {
            return Optional.empty();
        }

        JsonNode place;
        try {
            place = restClient.get()
                .uri(detailsUri(placeId))
                .header("X-Goog-Api-Key", apiKey)
                .header("X-Goog-FieldMask", DETAILS_FIELD_MASK)
                .retrieve()
                .body(JsonNode.class);
        } catch (RestClientResponseException exception) {
            throw apiException("place details", exception);
        }
        if (place == null || place.isMissingNode()) {
            return Optional.empty();
        }

        List<String> imageUrls = photoUrls(place.path("photos"));
        ExternalPlaceDetails details = new ExternalPlaceDetails(
            readText(place, "id"),
            readText(place, "nationalPhoneNumber"),
            readText(place, "websiteUri"),
            readDouble(place, "rating"),
            openingHours(place),
            imageUrls
        );
        if (!details.hasBusinessInfo() && details.imageUrls().isEmpty()) {
            return Optional.empty();
        }
        return Optional.of(details);
    }

    private URI detailsUri(String placeId) {
        String query = String.join("&",
            "languageCode=%s".formatted(encode(languageCode)),
            "regionCode=%s".formatted(encode(regionCode))
        );
        return URI.create("%s/places/%s?%s".formatted(baseUrl, encodePath(placeId), query));
    }

    private List<String> photoUrls(JsonNode photos) {
        if (photos == null || !photos.isArray()) {
            return List.of();
        }
        List<String> urls = new ArrayList<>();
        for (JsonNode photo : photos) {
            if (urls.size() >= maxPhotoCount) {
                break;
            }
            String name = readText(photo, "name");
            if (isBlank(name)) {
                continue;
            }
            findPhotoUri(name).ifPresent(urls::add);
        }
        return urls;
    }

    private Optional<String> findPhotoUri(String photoName) {
        try {
            JsonNode response = restClient.get()
                .uri(photoUri(photoName))
                .header("X-Goog-Api-Key", apiKey)
                .header("X-Goog-FieldMask", PHOTO_FIELD_MASK)
                .retrieve()
                .body(JsonNode.class);
            return Optional.ofNullable(readText(response, "photoUri"))
                .filter(value -> !value.isBlank());
        } catch (RestClientResponseException exception) {
            GooglePlacesApiException apiException = apiException("photo", exception);
            log.warn(
                "Google Places photo unavailable. status={}, reason={}",
                apiException.getStatusCode(),
                apiException.getReason()
            );
            return Optional.empty();
        } catch (RuntimeException ignored) {
            return Optional.empty();
        }
    }

    private GooglePlacesApiException apiException(
        String operation,
        RestClientResponseException exception
    ) {
        return new GooglePlacesApiException(
            operation,
            exception.getStatusCode().value(),
            googleErrorReason(exception),
            exception
        );
    }

    private String googleErrorReason(RestClientResponseException exception) {
        try {
            JsonNode error = exception.getResponseBodyAs(JsonNode.class).path("error");
            JsonNode details = error.path("details");
            if (details.isArray()) {
                for (JsonNode detail : details) {
                    String reason = readText(detail, "reason");
                    if (!isBlank(reason)) {
                        return reason;
                    }
                }
            }
            String status = readText(error, "status");
            if (!isBlank(status)) {
                return status;
            }
        } catch (RuntimeException ignored) {
            // Only expose Google's structured reason; never log the raw response body.
        }
        return "HTTP_%d".formatted(exception.getStatusCode().value());
    }

    private boolean hasApiKey() {
        if (!isBlank(apiKey)) {
            return true;
        }
        if (missingApiKeyLogged.compareAndSet(false, true)) {
            log.warn("Google Places enrichment unavailable: GOOGLE_PLACES_API_KEY is not configured");
        }
        return false;
    }

    private URI photoUri(String photoName) {
        String query = String.join("&",
            "maxHeightPx=720",
            "maxWidthPx=1080",
            "skipHttpRedirect=true"
        );
        return URI.create("%s/%s/media?%s".formatted(baseUrl, encodePath(photoName), query));
    }

    private PlaceOpeningHours openingHours(JsonNode place) {
        JsonNode current = place.path("currentOpeningHours");
        JsonNode regular = place.path("regularOpeningHours");
        JsonNode selected = current.isMissingNode() || current.isNull() ? regular : current;
        if (selected.isMissingNode() || selected.isNull()) {
            return PlaceOpeningHours.empty();
        }

        List<String> weekdayDescriptions = readStringList(selected.path("weekdayDescriptions"));
        return new PlaceOpeningHours(
            selected.has("openNow") ? selected.path("openNow").asBoolean() : null,
            todayDescription(weekdayDescriptions),
            weekdayDescriptions
        );
    }

    private String todayDescription(List<String> weekdayDescriptions) {
        if (weekdayDescriptions.isEmpty()) {
            return null;
        }
        int index = DayOfWeek.from(LocalDate.now()).getValue() - 1;
        if (index < 0 || index >= weekdayDescriptions.size()) {
            return null;
        }
        return weekdayDescriptions.get(index);
    }

    private List<String> readStringList(JsonNode node) {
        if (node == null || !node.isArray()) {
            return List.of();
        }
        List<String> values = new ArrayList<>();
        for (JsonNode item : node) {
            if (item.isTextual() && !item.asText().isBlank()) {
                values.add(item.asText());
            }
        }
        return values;
    }

    private static String readText(JsonNode node, String fieldName) {
        if (node == null || node.isMissingNode() || node.isNull()) {
            return null;
        }
        JsonNode value = node.path(fieldName);
        if (!value.isTextual()) {
            return null;
        }
        String text = value.asText().trim();
        return text.isBlank() ? null : text;
    }

    private static BigDecimal readDecimal(JsonNode node, String fieldName) {
        if (node == null || node.isMissingNode() || node.isNull()) {
            return null;
        }
        JsonNode value = node.path(fieldName);
        if (!value.isNumber()) {
            return null;
        }
        return value.decimalValue();
    }

    private static Double readDouble(JsonNode node, String fieldName) {
        if (node == null || node.isMissingNode() || node.isNull()) {
            return null;
        }
        JsonNode value = node.path(fieldName);
        if (!value.isNumber()) {
            return null;
        }
        return value.asDouble();
    }

    private static String encode(String value) {
        return UriUtils.encodeQueryParam(value == null ? "" : value, StandardCharsets.UTF_8);
    }

    private static String encodePath(String value) {
        return UriUtils.encodePath(value == null ? "" : value, StandardCharsets.UTF_8);
    }

    private static boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private static String stripTrailingSlash(String value) {
        if (value == null || value.isBlank()) {
            return "";
        }
        return value.endsWith("/") ? value.substring(0, value.length() - 1) : value;
    }

    private record GoogleTextSearchRequest(
        @JsonProperty("textQuery")
        String textQuery,
        @JsonProperty("languageCode")
        String languageCode,
        @JsonProperty("regionCode")
        String regionCode
    ) {
    }

    public record GooglePlaceSearchResult(
        String placeId,
        String name,
        String formattedAddress,
        BigDecimal latitude,
        BigDecimal longitude
    ) {
    }
}
