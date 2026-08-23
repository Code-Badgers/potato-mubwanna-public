package com.gamjamubwatna.notice.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.notice.api.AdminNoticeListResponse;
import com.gamjamubwatna.notice.api.AdminNoticeResponse;
import com.gamjamubwatna.notice.domain.Notice;
import com.gamjamubwatna.notice.domain.NoticeRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class AdminNoticeServiceTest {

    private static final Instant NOW = Instant.parse("2026-08-23T07:30:00Z");

    @Mock
    private NoticeRepository noticeRepository;

    private AdminNoticeService adminNoticeService;

    @BeforeEach
    void setUp() {
        adminNoticeService = new AdminNoticeService(
            noticeRepository,
            Clock.fixed(NOW, ZoneOffset.UTC)
        );
    }

    @Test
    void returnsPublishedAndDraftNoticesInRepositoryOrder() {
        Notice draft = notice(2L, "초안", false);
        Notice published = notice(1L, "게시 공지", true);
        when(noticeRepository.findAllByOrderByUpdatedAtDescIdDesc())
            .thenReturn(List.of(draft, published));

        AdminNoticeListResponse response = adminNoticeService.getNotices();

        assertThat(response.items()).extracting(AdminNoticeResponse::id)
            .containsExactly(2L, 1L);
        assertThat(response.items()).extracting(AdminNoticeResponse::published)
            .containsExactly(false, true);
    }

    @Test
    void createsDraftWithServerTimestamps() {
        when(noticeRepository.save(any(Notice.class))).thenAnswer(invocation -> {
            Notice notice = invocation.getArgument(0);
            ReflectionTestUtils.setField(notice, "id", 3L);
            return notice;
        });

        AdminNoticeResponse response = adminNoticeService.create("새 공지", "새 내용", false);

        assertThat(response.id()).isEqualTo(3L);
        assertThat(response.published()).isFalse();
        assertThat(response.publishedAt()).isEqualTo(NOW);
        assertThat(response.createdAt()).isEqualTo(NOW);
        assertThat(response.updatedAt()).isEqualTo(NOW);
    }

    @Test
    void updatesContentWithoutChangingPublicationState() {
        Notice notice = notice(4L, "기존 제목", true);
        Instant previousPublishedAt = notice.getPublishedAt();
        when(noticeRepository.findById(4L)).thenReturn(Optional.of(notice));

        AdminNoticeResponse response = adminNoticeService.update(4L, "수정 제목", "수정 내용");

        assertThat(response.title()).isEqualTo("수정 제목");
        assertThat(response.content()).isEqualTo("수정 내용");
        assertThat(response.published()).isTrue();
        assertThat(response.publishedAt()).isEqualTo(previousPublishedAt);
        assertThat(response.updatedAt()).isEqualTo(NOW);
    }

    @Test
    void publishesDraftAtCurrentTime() {
        Notice notice = notice(5L, "초안", false);
        when(noticeRepository.findById(5L)).thenReturn(Optional.of(notice));

        AdminNoticeResponse response = adminNoticeService.changePublication(5L, true);

        assertThat(response.published()).isTrue();
        assertThat(response.publishedAt()).isEqualTo(NOW);
        assertThat(response.updatedAt()).isEqualTo(NOW);
    }

    @Test
    void rejectsUnknownNotice() {
        when(noticeRepository.findById(404L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> adminNoticeService.update(404L, "제목", "내용"))
            .isInstanceOf(NoticeNotFoundException.class)
            .hasMessage("공지를 찾을 수 없습니다.");
        verify(noticeRepository).findById(404L);
    }

    private Notice notice(Long id, String title, boolean published) {
        Instant createdAt = Instant.parse("2026-08-20T00:00:00Z");
        Notice notice = new Notice(title, "공지 내용", published, createdAt, createdAt);
        ReflectionTestUtils.setField(notice, "id", id);
        return notice;
    }
}
