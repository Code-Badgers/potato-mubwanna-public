package com.gamjamubwatna.notice.application;

import static org.assertj.core.api.Assertions.assertThat;

import com.gamjamubwatna.notice.api.NoticeListResponse;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:admin_notice_integration;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.hibernate.ddl-auto=validate",
    "auth.jwt.secret=test-jwt-secret-must-be-long-enough"
})
@Transactional
class AdminNoticeIntegrationTest {

    @Autowired
    private AdminNoticeService adminNoticeService;

    @Autowired
    private NoticeService noticeService;

    @Test
    void publicationChangesAreReflectedInPublicNoticeList() {
        Long publishedId = adminNoticeService.create(
            "곧 숨길 공지",
            "게시 공지 내용",
            true
        ).id();
        Long draftId = adminNoticeService.create(
            "곧 게시할 공지",
            "초안 공지 내용",
            false
        ).id();

        assertThat(titles(noticeService.getPublishedNotices()))
            .contains("곧 숨길 공지")
            .doesNotContain("곧 게시할 공지");

        adminNoticeService.changePublication(publishedId, false);
        adminNoticeService.changePublication(draftId, true);

        assertThat(titles(noticeService.getPublishedNotices()))
            .contains("곧 게시할 공지")
            .doesNotContain("곧 숨길 공지");
    }

    private List<String> titles(NoticeListResponse response) {
        return response.items().stream()
            .map(item -> item.title())
            .toList();
    }
}
