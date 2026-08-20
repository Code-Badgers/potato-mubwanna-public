package com.gamjamubwatna.notice.api;

import com.gamjamubwatna.auth.api.AuthApiResponse;
import com.gamjamubwatna.notice.application.NoticeService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/notices")
public class NoticeController {

    private final NoticeService noticeService;

    public NoticeController(NoticeService noticeService) {
        this.noticeService = noticeService;
    }

    @GetMapping
    public ResponseEntity<AuthApiResponse<NoticeListResponse>> getNotices() {
        return ResponseEntity.ok(AuthApiResponse.success(noticeService.getPublishedNotices()));
    }
}
