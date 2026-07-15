package com.gamjamubwatna.audio.domain;

import com.gamjamubwatna.spot.domain.TouristSpot;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;

@Entity
@Table(
    name = "audio_guides",
    uniqueConstraints = @UniqueConstraint(
        name = "uk_audio_guides_spot_language",
        columnNames = {"tourist_spot_id", "language"}
    )
)
public class AudioGuide {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "audio_guide_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "tourist_spot_id", nullable = false)
    private TouristSpot touristSpot;

    @Column(name = "external_story_id", nullable = false, length = 100)
    private String externalStoryId;

    @Column(name = "title", nullable = false, length = 255)
    private String title;

    @Column(name = "audio_url", nullable = false, length = 1000)
    private String audioUrl;

    @Column(name = "script", columnDefinition = "TEXT")
    private String script;

    @Column(name = "character_script", columnDefinition = "TEXT")
    private String characterScript;

    @Column(name = "language", nullable = false, length = 20)
    private String language;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected AudioGuide() {
    }

    public AudioGuide(
        TouristSpot touristSpot,
        String externalStoryId,
        String title,
        String audioUrl,
        String script,
        String characterScript,
        String language,
        Instant now
    ) {
        this.touristSpot = touristSpot;
        this.externalStoryId = externalStoryId;
        this.title = title;
        this.audioUrl = audioUrl;
        this.script = script;
        this.characterScript = characterScript;
        this.language = language;
        this.createdAt = now;
        this.updatedAt = now;
    }

    public Long getId() {
        return id;
    }

    public TouristSpot getTouristSpot() {
        return touristSpot;
    }

    public String getExternalStoryId() {
        return externalStoryId;
    }

    public String getTitle() {
        return title;
    }

    public String getAudioUrl() {
        return audioUrl;
    }

    public String getScript() {
        return script;
    }

    public String getCharacterScript() {
        return characterScript;
    }

    public String getLanguage() {
        return language;
    }
}
