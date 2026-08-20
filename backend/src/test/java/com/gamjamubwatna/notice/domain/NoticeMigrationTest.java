package com.gamjamubwatna.notice.domain;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:notice_migration;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.hibernate.ddl-auto=validate",
    "auth.jwt.secret=test-jwt-secret-must-be-long-enough"
})
class NoticeMigrationTest {

    @Autowired
    private NoticeRepository noticeRepository;

    @Test
    void seedsPublishedNoticesWithoutMvpCopy() {
        List<Notice> notices =
            noticeRepository.findAllByPublishedTrueOrderByPublishedAtDescIdDesc();

        assertThat(notices).hasSize(2);
        assertThat(notices)
            .extracting(Notice::getContent)
            .noneMatch(content -> content.contains("공모전 MVP"));
    }
}
