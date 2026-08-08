# AWS ECR and SSM CD Setup

이 문서는 GitHub Actions가 장기 AWS 액세스 키나 SSH 키 없이 백엔드 이미지를 ECR에 게시하고 EC2에 배포하기 위한 최초 설정을 설명한다.

## 배포 기준

- 장기 `deploy` 또는 `release` 브랜치를 만들지 않는다.
- 일반 배포는 GitHub Actions의 `Backend Production Deploy`를 `main`에서 수동 실행한다.
- 운영 버전은 `backend-v0.1.0` 형식의 annotated tag로 기록한다. 이 태그를 push하면 같은 CD가 실행된다.
- 모든 이미지는 `sha-<12자리 커밋>` 태그로 ECR에 남아 같은 코드로 다시 배포할 수 있다.

## AWS 리소스

### 1. ECR 저장소

서울 리전에서 private ECR 저장소 `potato-mubwanna-backend`를 생성하고 tag immutability와 image scan을 활성화한다.

### 2. EC2 인스턴스 역할

EC2 역할에 다음 권한을 부여하고 운영 인스턴스에 연결한다.

- AWS 관리형 정책 `AmazonSSMManagedInstanceCore`
- 대상 ECR 저장소에 대한 `ecr:GetDownloadUrlForLayer`, `ecr:BatchGetImage`, `ecr:BatchCheckLayerAvailability`
- ECR 로그인에 필요한 `ecr:GetAuthorizationToken`

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

서버가 ECR에 로그인할 때 필요하므로 AWS CLI v2도 설치한다.

```bash
sudo apt update
sudo apt install -y curl unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
rm -rf /tmp/aws
unzip -q /tmp/awscliv2.zip -d /tmp
sudo /tmp/aws/install
aws --version
aws sts get-caller-identity
```

### 3. GitHub OIDC 공급자와 배포 역할

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

배포 역할에는 다음 범위만 허용한다. `<AWS_ACCOUNT_ID>`, `<AWS_REGION>`, `<EC2_INSTANCE_ID>`를 실제 값으로 바꾼다.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EcrLogin",
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*"
    },
    {
      "Sid": "PushBackendImage",
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeImages",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ],
      "Resource": "arn:aws:ecr:<AWS_REGION>:<AWS_ACCOUNT_ID>:repository/potato-mubwanna-backend"
    },
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

EC2 역할의 ECR pull 권한도 대상 저장소로 제한한다.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ],
      "Resource": "arn:aws:ecr:<AWS_REGION>:<AWS_ACCOUNT_ID>:repository/potato-mubwanna-backend"
    }
  ]
}
```

### 4. EC2 읽기 전용 Deploy Key

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
- `ECR_REPOSITORY`: `potato-mubwanna-backend`
- `EC2_INSTANCE_ID`: 운영 EC2 인스턴스 ID

production environment의 deployment branches and tags는 `main`과 `backend-v*`만 허용한다. 가능하면 required reviewer도 지정한다. 저장소나 계정 요금제에서 지원하지 않더라도 워크플로 자체가 다른 ref의 배포를 거부한다.

## 배포와 롤백

일반 배포는 Actions에서 `Backend Production Deploy`를 선택하고 `main`을 기준으로 실행한다.

운영 태그 배포:

```bash
git tag -a backend-v0.1.0 -m "백엔드 v0.1.0"
git push origin backend-v0.1.0
```

새 이미지의 pull, 기동 또는 헬스체크가 실패하면 CD는 직전 `BACKEND_IMAGE`로 자동 복구를 시도하고 작업을 실패 처리한다.

수동 롤백은 워크플로를 `main`에서 실행하고 `existing_image_tag`에 이전의 `sha-<12자리 커밋>` 태그를 입력한다. CD는 이미지를 다시 만들지 않고 해당 ECR 이미지를 검증한 뒤 재배포한다.

## 보안 원칙

- GitHub Secrets에 EC2 SSH 개인키나 장기 AWS 액세스 키를 저장하지 않는다.
- EC2의 GitHub Deploy Key는 read-only로 유지한다.
- SSM과 ECR 권한은 운영 인스턴스와 대상 저장소로 제한한다.
- 실제 `deploy/.env`를 Actions 로그, SSM 출력, Git 저장소에 노출하지 않는다.
