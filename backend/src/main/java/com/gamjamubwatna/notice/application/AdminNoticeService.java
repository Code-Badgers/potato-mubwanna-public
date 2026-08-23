package com.gamjamubwatna.notice.application;

import com.gamjamubwatna.notice.api.AdminNoticeListResponse;
import com.gamjamubwatna.notice.api.AdminNoticeResponse;
import com.gamjamubwatna.notice.domain.Notice;
import com.gamjamubwatna.notice.domain.NoticeRepository;
import java.time.Clock;
import java.time.Instant;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdminNoticeService {

    private final NoticeRepository noticeRepository;
    private final Clock clock;

    @Autowired
    public AdminNoticeService(NoticeRepository noticeRepository) {
        this(noticeRepository, Clock.systemUTC());
    }

    AdminNoticeService(NoticeRepository noticeRepository, Clock clock) {
        this.noticeRepository = noticeRepository;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public AdminNoticeListResponse getNotices() {
        return new AdminNoticeListResponse(
            noticeRepository.findAllByOrderByUpdatedAtDescIdDesc()
                .stream()
                .map(AdminNoticeResponse::from)
                .toList()
        );
    }

    @Transactional
    public AdminNoticeResponse create(String title, String content, boolean published) {
        Instant now = clock.instant();
        Notice notice = noticeRepository.save(new Notice(
            title,
            content,
            published,
            now,
            now
        ));
        return AdminNoticeResponse.from(notice);
    }

    @Transactional
    public AdminNoticeResponse update(Long noticeId, String title, String content) {
        Notice notice = findNotice(noticeId);
        notice.updateContent(title, content, clock.instant());
        return AdminNoticeResponse.from(notice);
    }

    @Transactional
    public AdminNoticeResponse changePublication(Long noticeId, boolean published) {
        Notice notice = findNotice(noticeId);
        notice.changePublication(published, clock.instant());
        return AdminNoticeResponse.from(notice);
    }

    private Notice findNotice(Long noticeId) {
        return noticeRepository.findById(noticeId)
            .orElseThrow(NoticeNotFoundException::new);
    }
}
