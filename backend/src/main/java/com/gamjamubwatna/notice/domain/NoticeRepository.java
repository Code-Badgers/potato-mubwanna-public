package com.gamjamubwatna.notice.domain;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface NoticeRepository extends JpaRepository<Notice, Long> {

    List<Notice> findAllByPublishedTrueOrderByPublishedAtDescIdDesc();
}
