import '../../../app/config/app_environment.dart';
import 'legal_document.dart';

class LegalDocumentCatalog {
  const LegalDocumentCatalog._();

  static LegalDocument document(LegalDocumentType type) {
    return switch (type) {
      LegalDocumentType.serviceTerms => _serviceTerms,
      LegalDocumentType.privacyPolicy => _privacyPolicy,
      LegalDocumentType.locationServiceTerms => _locationServiceTerms,
      LegalDocumentType.healthDataConsent => _healthDataConsent,
    };
  }

  static const _serviceTerms = LegalDocument(
    type: LegalDocumentType.serviceTerms,
    title: '서비스 이용약관',
    summary: '감자무봤나 계정과 관광·수집 서비스를 이용하기 위한 기본 약관입니다.',
    effectiveDate: AppEnvironment.legalEffectiveDate,
    sections: [
      LegalDocumentSection(
        title: '제1조 목적',
        paragraphs: [
          '이 약관은 감자무봤나 운영자와 이용자 사이의 서비스 이용 조건, 권리, 의무 및 책임사항을 정하는 것을 목적으로 합니다.',
        ],
      ),
      LegalDocumentSection(
        title: '제2조 서비스 내용',
        items: [
          '강원 관광지·음식점·카페·체험 장소 정보와 지도 탐색',
          'GPS 기반 방문 인증, 디지털 스탬프와 감자 캐릭터 수집',
          '미션, 여행 기록, 오디오 가이드, 쿠폰 및 알림',
          '걸음 수를 이용한 감자 성장 기능(별도 동의 및 기기 권한을 허용한 경우)',
        ],
      ),
      LegalDocumentSection(
        title: '제3조 약관의 게시와 변경',
        paragraphs: [
          '운영자는 이 약관을 앱의 첫 화면과 설정에서 확인할 수 있게 게시합니다. 관련 법령을 위반하지 않는 범위에서 약관을 변경할 수 있으며, 중요한 변경은 시행일 30일 전부터 앱 공지 등으로 알립니다. 이용자에게 불리하지 않은 변경은 시행일 7일 전부터 알릴 수 있습니다.',
        ],
      ),
      LegalDocumentSection(
        title: '제4조 계정과 로그인',
        paragraphs: [
          '서비스는 카카오 로그인을 사용합니다. 이용자는 본인의 계정을 사용해야 하며, 계정 접근수단을 안전하게 관리해야 합니다. 카카오 서비스 장애나 이용 제한으로 로그인이 일시적으로 제한될 수 있습니다.',
        ],
      ),
      LegalDocumentSection(
        title: '제5조 이용자의 의무',
        items: [
          '타인의 계정이나 위치를 도용하지 않습니다.',
          'GPS 조작, QR 위조, 자동화 도구 등으로 방문·미션 결과를 부정하게 만들지 않습니다.',
          '타인의 권리, 법령 또는 공공질서를 침해하는 사진과 정보를 올리지 않습니다.',
          '서비스의 정상 운영을 방해하거나 보안상 취약점을 악용하지 않습니다.',
        ],
      ),
      LegalDocumentSection(
        title: '제6조 서비스 변경과 중단',
        paragraphs: [
          '점검, 장애, 천재지변, 제휴처 또는 외부 API의 사정이 있는 경우 서비스의 전부 또는 일부가 변경되거나 중단될 수 있습니다. 운영자는 예측 가능한 경우 앱 공지 등으로 미리 알립니다.',
        ],
      ),
      LegalDocumentSection(
        title: '제7조 콘텐츠와 쿠폰',
        paragraphs: [
          '관광지 정보, 혼잡도, 영업정보와 외부 오디오 자료는 제공기관의 갱신 시점에 따라 실제 현황과 다를 수 있습니다. 쿠폰의 사용처, 수량과 유효기간은 각 쿠폰에 표시된 조건을 따릅니다.',
        ],
      ),
      LegalDocumentSection(
        title: '제8조 이용 종료',
        paragraphs: [
          '이용자는 설정의 회원 탈퇴 기능으로 서비스 이용을 종료할 수 있습니다. 탈퇴 시 법령상 보존이 필요한 자료를 제외한 계정과 활동 기록은 복구할 수 없도록 삭제됩니다.',
        ],
      ),
      LegalDocumentSection(
        title: '제9조 책임 제한과 분쟁',
        paragraphs: [
          '운영자는 고의 또는 과실이 없는 외부 서비스 장애, 이용자 귀책사유나 불가항력으로 발생한 손해에 책임을 지지 않습니다. 분쟁은 대한민국 법령을 따르며, 합의되지 않으면 민사소송법상 관할 법원에서 해결합니다.',
        ],
      ),
      LegalDocumentSection(
        title: '제10조 운영자 정보',
        items: [
          '상호: ${AppEnvironment.legalBusinessName}',
          '대표자: ${AppEnvironment.legalRepresentativeName}',
          '전화: ${AppEnvironment.legalContactPhone}',
          '이메일: ${AppEnvironment.legalContactEmail}',
        ],
      ),
    ],
  );

  static const _locationServiceTerms = LegalDocument(
    type: LegalDocumentType.locationServiceTerms,
    title: '위치기반서비스 이용약관',
    summary: '현재 위치를 주변 탐색과 방문 인증에 이용하는 범위와 이용자의 권리를 안내합니다.',
    effectiveDate: AppEnvironment.legalEffectiveDate,
    sections: [
      LegalDocumentSection(
        title: '제1조 목적과 동의',
        paragraphs: [
          '이 약관은 감자무봤나가 개인위치정보를 이용하여 제공하는 위치기반서비스의 내용과 개인위치정보주체의 권리를 정합니다. 위치정보 이용 동의는 선택사항이며, 동의하지 않아도 위치 기능을 제외한 지도·관광지 상세·오디오 가이드 등을 이용할 수 있습니다.',
        ],
      ),
      LegalDocumentSection(
        title: '제2조 사업자 정보',
        items: [
          '상호: ${AppEnvironment.legalBusinessName}',
          '대표자: ${AppEnvironment.legalRepresentativeName}',
          '전화: ${AppEnvironment.legalContactPhone}',
          '이메일: ${AppEnvironment.legalContactEmail}',
        ],
      ),
      LegalDocumentSection(
        title: '제3조 위치기반서비스의 내용과 요금',
        items: [
          '현재 위치 주변 감자 스팟 탐색과 지도상의 현재 위치 표시',
          '관광지 반경 내 방문 여부 확인과 스탬프·미션 처리',
          '위치와 방문 이력을 이용한 여행 기록 및 다음 장소 안내',
          '위치기반서비스 이용료는 무료이며, 통신요금은 이용자에게 부과될 수 있습니다.',
        ],
      ),
      LegalDocumentSection(
        title: '제4조 개인위치정보의 이용과 보유',
        paragraphs: [
          '방문 인증을 요청할 때 단말기의 GPS 위도·경도를 서버로 암호화하여 전송하고 관광지 좌표와의 거리를 계산합니다. 원본 위도·경도는 거리 계산이 끝나면 데이터베이스에 저장하지 않습니다.',
          '인증에 성공하면 관광지, 인증 시각과 계산된 거리를 방문 기록으로 저장하고 회원 탈퇴 시까지 서비스 이력으로 이용합니다. 법령에 따라 별도 보존이 필요한 이용 사실 확인자료는 정해진 기간 동안 분리하여 보존합니다.',
        ],
      ),
      LegalDocumentSection(
        title: '제5조 이용·제공사실 확인자료',
        paragraphs: [
          '운영자는 위치정보법에 따라 개인위치정보 이용·제공사실 확인자료를 자동으로 기록하고 최소 6개월 보관합니다. 이 자료는 위치정보를 제외한 이용자 식별값, 이용 일시, 취득 경로, 이용 목적과 서비스 결과로 구성됩니다.',
        ],
      ),
      LegalDocumentSection(
        title: '제6조 제3자 제공',
        paragraphs: [
          '운영자는 개인위치정보를 제3자에게 제공하지 않습니다. 향후 제3자 제공 기능을 도입하는 경우 제공받는 자, 목적, 항목과 보유기간을 알리고 별도 동의를 받으며, 제공할 때마다 법령이 정한 방법으로 통보합니다.',
        ],
      ),
      LegalDocumentSection(
        title: '제7조 이용자의 권리',
        items: [
          '개인위치정보 이용 동의의 전부 또는 일부를 언제든 철회할 수 있습니다.',
          '개인위치정보 이용의 일시 중지를 요구할 수 있습니다.',
          '본인에 대한 위치정보 이용·제공사실 확인자료의 열람 또는 고지를 요구할 수 있습니다.',
          '동의 철회는 앱 설정 또는 운영자 연락처를 통해 요청할 수 있습니다.',
        ],
      ),
      LegalDocumentSection(
        title: '제8조 개인위치정보 관리책임자',
        items: [
          '책임자: ${AppEnvironment.legalRepresentativeName}',
          '전화: ${AppEnvironment.legalContactPhone}',
          '이메일: ${AppEnvironment.legalContactEmail}',
        ],
      ),
      LegalDocumentSection(
        title: '제9조 법정대리인과 보호의무자',
        paragraphs: [
          '만 14세 미만 아동 또는 관련 법령상 보호가 필요한 이용자의 개인위치정보를 이용해야 하는 경우 법정대리인 또는 보호의무자의 동의를 포함하여 관계 법령이 정한 절차를 따릅니다.',
        ],
      ),
    ],
  );

  static const _healthDataConsent = LegalDocument(
    type: LegalDocumentType.healthDataConsent,
    title: '걸음 정보 수집·이용 동의',
    summary: '감자 성장 기능을 위해 건강 플랫폼의 걸음 수를 읽고 서버에 저장하는 선택 동의입니다.',
    effectiveDate: AppEnvironment.legalEffectiveDate,
    sections: [
      LegalDocumentSection(
        title: '수집·이용 목적',
        items: [
          '오늘·주간·월간 걸음 통계 제공',
          '이동거리에 따른 대표 감자 성장 및 미션 진행',
          '중복 성장 보상을 방지하기 위한 일별 누적값 비교',
        ],
      ),
      LegalDocumentSection(
        title: '처리 항목',
        items: [
          '활동 날짜, 걸음 수, 걸음 수로 계산한 이동거리',
          '수집 출처(Apple HealthKit 또는 Android Health Connect)',
          '동기화 시각',
        ],
      ),
      LegalDocumentSection(
        title: '보유기간과 거부 권리',
        paragraphs: [
          '동의 철회 또는 회원 탈퇴 시까지 보유하며, 관계 법령에 따른 보존 의무가 있는 경우 해당 기간 동안 분리 보관합니다.',
          '이 동의는 선택사항입니다. 거부하거나 철회해도 지도, 관광지 정보, 방문 인증 등 다른 기능은 이용할 수 있지만 걸음 기반 통계·감자 성장·걸음 미션은 제한됩니다.',
        ],
      ),
      LegalDocumentSection(
        title: '철회 방법',
        paragraphs: [
          '앱 설정에서 동의를 철회하고, 기기 설정의 HealthKit 또는 Health Connect에서도 감자무봤나의 접근권한을 해제할 수 있습니다.',
        ],
      ),
    ],
  );

  static const _privacyPolicy = LegalDocument(
    type: LegalDocumentType.privacyPolicy,
    title: '개인정보처리방침',
    summary: '감자무봤나가 어떤 개인정보를 왜, 얼마나 보관하는지 안내합니다.',
    effectiveDate: AppEnvironment.legalEffectiveDate,
    sections: [
      LegalDocumentSection(
        title: '1. 개인정보처리자',
        paragraphs: [
          '${AppEnvironment.legalBusinessName}(이하 “운영자”)은 개인정보 보호법과 위치정보법 등 관계 법령을 준수합니다.',
        ],
        items: [
          '대표자: ${AppEnvironment.legalRepresentativeName}',
        ],
      ),
      LegalDocumentSection(
        title: '2. 처리 목적·항목·보유기간',
        items: [
          '회원 가입·로그인: 카카오 회원번호, 닉네임, 이메일 및 프로필 이미지(카카오에서 제공된 경우) / 회원 탈퇴 시까지',
          '관광·수집 서비스: 즐겨찾기, 방문 관광지, 방문 시각, 계산된 거리, 스탬프, 미션, 감자, 보상·쿠폰 기록 / 회원 탈퇴 시까지',
          '방문 인증: 요청 시 GPS 위도·경도 / 거리 계산 직후 원본 좌표 즉시 파기',
          '걸음 성장 기능: 활동 날짜, 걸음 수, 계산 이동거리, 수집 출처와 동기화 시각 / 선택 동의 철회 또는 회원 탈퇴 시까지',
          '미션·여행 기록: 이용자가 선택한 사진, 파일 정보와 업로드 시각 / 해당 기록 삭제 또는 회원 탈퇴 시까지',
          '알림: 기기 푸시 토큰, 플랫폼과 갱신 시각 / 알림 동의 철회, 토큰 만료 또는 회원 탈퇴 시까지',
          '보안·장애 대응: 접속 IP, 요청 시각, 기기·OS·앱 버전, 오류 및 접속 기록 / 원칙적으로 3개월',
        ],
      ),
      LegalDocumentSection(
        title: '3. 개인위치정보 처리',
        paragraphs: [
          '현재 위치는 주변 탐색과 방문 인증 요청을 처리하기 위해 이용합니다. 원본 좌표는 방문 거리 계산 후 데이터베이스에 저장하지 않으며 제3자에게 제공하지 않습니다. 관광지, 인증 시각과 계산된 거리는 이용자의 여행 기록 제공을 위해 회원 탈퇴 시까지 보유합니다.',
          '위치정보 이용·제공사실 확인자료는 위치정보법에 따라 자동 기록하여 최소 6개월 보관한 뒤 복구할 수 없는 방법으로 파기합니다.',
        ],
      ),
      LegalDocumentSection(
        title: '4. 개인정보의 제3자 제공',
        paragraphs: [
          '운영자는 이용자의 개인정보와 개인위치정보를 제3자에게 제공하지 않습니다. 법령에 특별한 근거가 있거나 이용자에게 제공받는 자, 목적, 항목과 보유기간을 알리고 별도 동의를 받은 경우에만 제공합니다.',
        ],
      ),
      LegalDocumentSection(
        title: '5. 처리업무 위탁',
        items: [
          'Amazon Web Services, Inc. 및 한국아마존웹서비스 유한책임회사: 서울 리전의 서버·데이터베이스 인프라 운영',
          'Google LLC: Firebase Cloud Messaging을 이용한 선택적 푸시 알림 전송',
          '카카오 주식회사: 카카오 로그인과 지도 SDK 제공',
        ],
      ),
      LegalDocumentSection(
        title: '6. 국외 이전',
        paragraphs: [
          '푸시 알림을 허용한 경우 기기 푸시 토큰과 알림 전송 정보가 암호화된 네트워크를 통해 Google LLC의 글로벌 인프라에서 처리될 수 있습니다. 이전 목적은 알림 전송이며, 알림 동의 철회 또는 토큰 만료 시까지 처리됩니다. 이용자는 알림을 거부할 수 있고 이 경우 푸시 알림만 제한됩니다.',
        ],
      ),
      LegalDocumentSection(
        title: '7. 파기 절차와 방법',
        paragraphs: [
          '보유기간이 끝나거나 처리 목적이 달성된 개인정보는 지체 없이 파기합니다. 전자 파일은 복구할 수 없는 방법으로 삭제하고, 법령상 보존 의무가 있는 자료는 다른 정보와 분리하여 해당 기간 동안만 보관합니다.',
        ],
      ),
      LegalDocumentSection(
        title: '8. 이용자의 권리와 행사방법',
        paragraphs: [
          '이용자는 개인정보와 위치정보의 열람, 정정, 삭제, 처리정지, 동의 철회와 회원 탈퇴를 요구할 수 있습니다. 앱 설정 또는 아래 개인정보 보호책임자 연락처로 요청하면 본인 확인 후 관계 법령에 따라 처리합니다.',
        ],
      ),
      LegalDocumentSection(
        title: '9. 안전성 확보조치',
        items: [
          '전송구간 암호화(HTTPS)와 인증 토큰의 안전한 저장',
          '개인정보 접근권한 최소화 및 접근 기록 관리',
          '원본 위치좌표 최소 처리와 데이터베이스 미저장',
          '백업, 취약점 점검과 침해사고 대응 절차 운영',
        ],
      ),
      LegalDocumentSection(
        title: '10. 개인정보·개인위치정보 보호책임자',
        items: [
          '책임자: ${AppEnvironment.legalRepresentativeName}',
          '전화: ${AppEnvironment.legalContactPhone}',
          '이메일: ${AppEnvironment.legalContactEmail}',
        ],
      ),
      LegalDocumentSection(
        title: '11. 권익침해 구제',
        items: [
          '개인정보침해 신고센터: 국번 없이 118',
          '개인정보분쟁조정위원회: 1833-6972',
          '경찰청 사이버범죄 신고시스템: 국번 없이 182',
        ],
      ),
      LegalDocumentSection(
        title: '12. 방침의 변경',
        paragraphs: [
          '이 방침의 내용이 변경되면 시행 전 앱 공지 등을 통해 변경 내용과 시행일을 알립니다. 중요한 변경은 시행일 30일 전에 안내합니다.',
        ],
      ),
    ],
  );
}
