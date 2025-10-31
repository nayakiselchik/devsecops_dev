# Secure Python App: `41_scan_stream_default.py`

цей репозиторій містить мінімальний, але повний каркас застосунку на Python із CI/CD, підписуванням артефактів Cosign, SBOM (Syft), перевіркою SBOM (Grype), та Scorecard.

## встановлення та запуск локально
```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
curl -O https://raw.githubusercontent.com/savostyanenko/example_of_vulnerable_code_2/main/41_scan_stream_default.py
```

## збірка псевдобінаря
```bash
make build
```

## Алгоритм виконання (від Tech Writer)
1. **Структура репозиторію**: `41_scan_stream_default.py`, `README.md`, `requirements.txt`, `Makefile`, `.github/workflows/ci-cd.yml`, файли SBOM, підписи Cosign.
2. **Код**: скопіювати `41_scan_stream_default.py` з `savostyanenko/example_of_vulnerable_code_2` (скрипт `fetch_source.sh` робить це автоматично).
3. **Залежності**: фіксуємо лише реальні імпорти скрипта у `requirements.txt` (за замовчуванням — порожньо).
4. **Makefile**: цілі `install`, `build`, `clean`.
5. **Гілки**: `dev` → `stage` → `main`. У `main` потрапляє код лише через Pull Request (MR).
6. **CI/CD**: на PR і на тег `v*` — збірка, SBOM (Syft), перевірка SBOM (Grype), підпис Cosign, Scorecard; на тег — реліз **v1.0.0** з артефактами.
7. **Безпека**: Cosign keyless, SBOM (spdx та cyclonedx), Grype репорт, OSSF Scorecard.
8. **Ролі**: 4 користувачі; лише 1 має право пушити у `main`; усі працюють через PR.

## Стратегія гілок
- `dev` — активна розробка
- `stage` — передпродове тестування
- `main` — продакшн; захищена гілка, тільки через PR

## CI/CD коротко
- **build**: збірка псевдобінаря `pyinstaller` та пакування артефактів
- **sbom**: генерація SBOM (`spdx-json`, `cyclonedx-json`) за допомогою Syft
- **scan**: перевірка SBOM Grype (`vulnerabilities.json`)
- **sign**: Cosign keyless підпис `artifact.zip` (+ сертифікат)
- **release**: створення GitHub Release на тег `v*` і завантаження артефактів

## Реліз 1.0.0
```bash
git tag -a v1.0.0 -m "Release 1.0.0"
git push origin v1.0.0
```
Пайплайн створить реліз і додасть туди артефакти.

## Версія
**1.0.0**
