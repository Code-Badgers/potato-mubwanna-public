package com.gamjamubwatna.notice.application;

import com.gamjamubwatna.notice.api.NoticeListResponse;
import com.gamjamubwatna.notice.api.NoticeResponse;
import com.gamjamubwatna.notice.domain.NoticeRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class NoticeService {

    private final NoticeRepository noticeRepository;

    public NoticeService(NoticeRepository noticeRepository) {
        this.noticeRepository = noticeRepository;
    }

    @Transactional(readOnly = true)
    public NoticeListResponse getPublishedNotices() {
        return new NoticeListResponse(
            noticeRepository.findAllByPublishedTrueOrderByPublishedAtDescIdDesc()
                .stream()
                .map(NoticeResponse::from)
                .toList()
        );
    }
}
