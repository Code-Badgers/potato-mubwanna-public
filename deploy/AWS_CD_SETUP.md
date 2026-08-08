# AWS SSM CD Setup

이 문서는 GitHub Actions가 장기 AWS 액세스 키나 EC2 SSH 개인키 없이 SSM으로 운영 서버에 배포하기 위한 최초 설정을 설명한다. 별도 컨테이너 저장소는 사용하지 않으며 EC2가 배포할 Git 커밋에서 백엔드 이미지를 직접 빌드한다.

## 배포 기준

- 장기 `deploy` 또는 `release` 브랜치를 만들지 않는다.
- 일반 배포는 GitHub Actions의 `Backend Production Deploy`를 `main`에서 수동 실행한다.
- 운영 버전은 `backend-v0.1.0` 형식의 annotated tag로 기록하며 태그를 push하면 같은 CD가 실행된다.
- EC2 로컬 이미지에는 `potato-mubwanna-backend:sha-<12자리 커밋>` 태그를 붙인다.
- 배포 성공 후 현재 이미지와 직전 이미지 외의 오래된 백엔드 이미지를 정리한다.

## 동작과 자원 영향

GitHub Actions는 테스트를 통과한 Git SHA를 SSM으로 전달한다. EC2는 해당 커밋을 checkout하고 Docker 이미지를 빌드한 뒤 Compose로 교체한다.

- 별도 컨테이너 저장소와 관련 권한이 필요 없다.
- 배포 중 EC2에서 Java 컴파일과 Docker 이미지 빌드가 실행되므로 CPU 사용량이 높아지고 배포가 느릴 수 있다.
- 기존 서비스는 새 이미지 빌드가 끝날 때까지 계속 실행된다.
- 운영 인스턴스에는 2GB 스왑을 유지하고 배포 중 메모리와 디스크 사용량을 확인한다.

## AWS 리소스

### 1. EC2 인스턴스 역할

EC2 역할에 AWS 관리형 정책 `AmazonSSMManagedInstanceCore`를 연결하고 운영 인스턴스에 연결한다. ECR 권한과 서버용 AWS CLI는 필요하지 않다.

Ubuntu 24.04 AWS AMI에는 일반적으로 SSM Agent가 Snap으로 미리 설치되어 있다. 다음 명령으로 실행 상태를 확인한다.

```bash
sudo snap list amazon-ssm-agent
sudo snap services amazon-ssm-agent
```

설치되어 있지 않거나 중지되어 있으면 다음 명령을 실행한다.

```bash
sudo snap install amazon-ssm-agent --classic
sudo snap start amazon-ssm-agent
```

### 2. GitHub OIDC 공급자와 배포 역할

IAM OIDC 공급자 `https://token.actions.githubusercontent.com`을 등록하고 audience는 `sts.amazonaws.com`을 사용한다.

GitHub 배포 역할의 신뢰 정책은 production environment에서 실행되는 이 저장소만 허용한다.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<AWS_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:Code-Badgers/potato-mubwanna:environment:production"
        }
      }
    }
  ]
}
```

배포 역할에는 SSM 실행과 결과 조회만 허용한다. `<AWS_ACCOUNT_ID>`, `<AWS_REGION>`, `<EC2_INSTANCE_ID>`를 실제 값으로 바꾼다.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "RunDeploymentOnProductionInstance",
      "Effect": "Allow",
      "Action": "ssm:SendCommand",
      "Resource": [
        "arn:aws:ssm:<AWS_REGION>::document/AWS-RunShellScript",
        "arn:aws:ec2:<AWS_REGION>:<AWS_ACCOUNT_ID>:instance/<EC2_INSTANCE_ID>"
      ]
    },
    {
      "Sid": "ReadDeploymentResult",
      "Effect": "Allow",
      "Action": "ssm:GetCommandInvocation",
      "Resource": "*"
    }
  ]
}
```

### 3. EC2 읽기 전용 Deploy Key

저장소가 private이므로 EC2의 `ubuntu` 사용자로 읽기 전용 키를 만든다.

```bash
ssh-keygen -t ed25519 -f ~/.ssh/potato-mubwanna-deploy -N ''
cat ~/.ssh/potato-mubwanna-deploy.pub
```

출력된 공개키를 GitHub 저장소의 **Settings → Deploy keys**에 등록하고 쓰기 권한은 허용하지 않는다. `~/.ssh/config`에는 이 키를 GitHub 전용으로 지정한다.

```sshconfig
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/potato-mubwanna-deploy
  IdentitiesOnly yes
```

GitHub 호스트 키 지문을 확인한 뒤 저장소를 준비한다.

```bash
sudo mkdir -p /opt/potato-mubwanna
sudo chown ubuntu:ubuntu /opt/potato-mubwanna
git clone git@github.com:Code-Badgers/potato-mubwanna.git /opt/potato-mubwanna
cd /opt/potato-mubwanna
cp deploy/.env.example deploy/.env
chmod 600 deploy/.env
```

`deploy/.env`의 비밀번호, JWT/쿠폰 서명 키, 외부 API 키를 실제 운영값으로 바꾼다. 이 파일은 Git에 커밋하지 않는다.

## GitHub production environment

GitHub 저장소의 **Settings → Environments → production**에 다음 environment variables를 추가한다.

- `AWS_ROLE_ARN`: GitHub OIDC 배포 역할 ARN
- `AWS_REGION`: `ap-northeast-2`
- `EC2_INSTANCE_ID`: 운영 EC2 인스턴스 ID

production environment의 deployment branches and tags는 `main`과 `backend-v*`만 허용한다. 가능하면 required reviewer도 지정한다. 저장소나 계정 요금제에서 지원하지 않더라도 워크플로 자체가 다른 ref의 배포를 거부한다.

## 배포와 롤백

일반 배포는 Actions에서 `Backend Production Deploy`를 선택하고 `main`을 기준으로 실행한다.

운영 태그 배포:

```bash
git tag -a backend-v0.1.0 -m "백엔드 v0.1.0"
git push origin backend-v0.1.0
```

새 이미지의 기동 또는 헬스체크가 실패하면 CD는 직전 `BACKEND_IMAGE`로 자동 복구를 시도하고 작업을 실패 처리한다.

수동 롤백은 워크플로를 `main`에서 실행하고 `existing_image_tag`에 EC2에 남아 있는 이전의 `sha-<12자리 커밋>` 태그를 입력한다. CD는 해당 로컬 이미지가 있는지 확인한 뒤 다시 빌드하지 않고 재배포한다.

```bash
docker image ls potato-mubwanna-backend
```

CD는 현재 이미지와 직전 이미지만 유지하므로 그보다 오래된 버전은 다시 checkout해 새로 배포해야 한다.

## 보안 원칙

- GitHub Secrets에 EC2 SSH 개인키나 장기 AWS 액세스 키를 저장하지 않는다.
- EC2의 GitHub Deploy Key는 read-only로 유지한다.
- GitHub 배포 역할의 SSM 권한은 운영 인스턴스 하나로 제한한다.
- 실제 `deploy/.env`를 Actions 로그, SSM 출력, Git 저장소에 노출하지 않는다.
