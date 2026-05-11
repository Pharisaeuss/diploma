# 🚀 AWS Infrastructure Automation

Дипломний проєкт — повністю автоматизована хмарна інфраструктура на базі AWS,  
побудована за принципами **Infrastructure as Code** та **GitOps**.

---

## 📌 Про що цей проєкт

Проєкт демонструє побудову та управління хмарною інфраструктурою для веб-застосунку
(FastAPI + PostgreSQL) без жодного ручного налаштування через AWS Console.
Уся інфраструктура описана кодом, версіонується у Git і розгортається автоматично
через GitHub Actions.

---

## 🗂️ Структура репозиторію

```
.
├── terraform/          # Опис інфраструктури (VPC, EC2, RDS, IAM, S3...)
│   ├── modules/        # Перевикористовувані модулі (network, rds, iam, monitoring…)
│   └── environments/   # Конфігурації для dev / stage / prod
│
├── packer/             # Збірка AMI-образів для EC2
│   ├── base-ami.pkr.hcl   # Базовий образ (ОС + утиліти)
│   └── app-ami.pkr.hcl    # Образ застосунку (FastAPI + Nginx)
│
├── ansible/            # Конфігурування EC2-інстансів
│   ├── playbook.yml           # Плейбук: пошук інстансів + їх налаштування
│   ├── inventory_aws_ec2.yml  # Динамічний інвентар (AWS EC2 plugin)
│   └── ansible.cfg            # Конфігурація Ansible
│
└── .github/workflows/  # CI/CD пайплайни GitHub Actions
    ├── infrastructure.yml     # Terraform: розгортання інфраструктури
    ├── build-base-ami.yml     # Packer: збірка базового AMI
    ├── build-app-ami.yml      # Packer: збірка AMI застосунку
    ├── configuration.yml      # Ansible: конфігурування EC2
    └── destroy.yml            # Terraform: знищення інфраструктури
```

---

## ⚙️ Як це працює

```
Git push / Manual trigger
        │
        ▼
┌─────────────────┐     ┌──────────────┐     ┌─────────────────┐
│   Terraform     │────▶│    Packer    │────▶│    Ansible      │
│  (інфраструктура)│     │  (AMI-образ) │     │ (конфігурація)  │
└─────────────────┘     └──────────────┘     └─────────────────┘
  VPC, RDS, ALB,          FastAPI + Nginx       Оновлення пакетів,
  EC2, IAM, S3            запечені в образ      NTP, SSH, firewall,
                                                CloudWatch Agent
```

1. **Terraform** створює всю мережеву інфраструктуру та ресурси AWS.
2. **Packer** збирає AMI-образ EC2 з попередньо встановленим застосунком.
3. **Ansible** знаходить запущені EC2-інстанси через **динамічний інвентар**
   (без жодного хардкоду IP-адрес) і застосовує базову конфігурацію.

---

## 🔐 Безпека

- AWS-автентифікація через **OIDC** (без статичних ключів у секретах).
- Секрети зберігаються у **AWS SSM Parameter Store**.
- SSH налаштований лише на ключі, без пароля, root-доступ заборонено.

---

## 🛠️ Технології

| Інструмент | Призначення |
|---|---|
| Terraform + Terragrunt | IaC, управління інфраструктурою |
| Packer | Збірка машинних образів (AMI) |
| Ansible | Конфігураційне управління EC2 |
| GitHub Actions | CI/CD пайплайни |
| AWS (EC2, RDS, S3, SSM, CloudWatch) | Хмарна платформа |
