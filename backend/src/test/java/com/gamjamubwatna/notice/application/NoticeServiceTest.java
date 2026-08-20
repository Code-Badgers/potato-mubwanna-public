package com.gamjamubwatna.notice.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.notice.api.NoticeListResponse;
import com.gamjamubwatna.notice.domain.Notice;
import com.gamjamubwatna.notice.domain.NoticeRepository;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class NoticeServiceTest {

    @Mock
    private NoticeRepository noticeRepository;

    private NoticeService noticeService;

    @BeforeEach
    void setUp() {
        noticeService = new NoticeService(noticeRepository);
    }

    @Test
    void returnsPublishedNoticesInRepositoryOrder() {
        Notice notice = new Notice(
            "서비스 이용 안내",
            "공지 내용",
            true,
            Instant.parse("2026-08-20T00:00:00Z"),
            Instant.parse("2026-08-20T00:00:00Z")
        );
        ReflectionTestUtils.setField(notice, "id", 7L);
        when(noticeRepository.findAllByPublishedTrueOrderByPublishedAtDescIdDesc())
            .thenReturn(List.of(notice));

        NoticeListResponse response = noticeService.getPublishedNotices();

        assertThat(response.items()).hasSize(1);
        assertThat(response.items().getFirst().id()).isEqualTo(7L);
        assertThat(response.items().getFirst().title()).isEqualTo("서비스 이용 안내");
        assertThat(response.items().getFirst().content()).isEqualTo("공지 내용");
        assertThat(response.items().getFirst().publishedAt())
            .isEqualTo(Instant.parse("2026-08-20T00:00:00Z"));
    }
}
