# -------- Configuration --------
APP_NAME    ?= 41_scan_stream_default
ENTRYPOINT  ?= 41_scan_stream_default.py
PYTHON      ?= python3
PYINSTALLER ?= pyinstaller

# Вихідні каталоги PyInstaller
BUILD_DIR   := build
DIST_DIR    := dist

# Додаткові опції PyInstaller (за потреби додавай свої)
PYI_FLAGS   := --onefile --clean --name $(APP_NAME) --console

# -------- Phony targets --------
.PHONY: all build rebuild run clean distclean check

all: build

# Перевіряємо наявність вхідної точки
check:
	@if [ ! -f "$(ENTRYPOINT)" ]; then \
		echo "ERROR: ENTRYPOINT '$(ENTRYPOINT)' не знайдено. Задай правильний шлях: make build ENTRYPOINT=src/main.py"; \
		exit 1; \
	fi

# Основна збірка "псевдобінарника"
build: check
	@echo "==> Building $(APP_NAME) from $(ENTRYPOINT)"
	$(PYINSTALLER) $(PYI_FLAGS) $(ENTRYPOINT)
	@# Переконуємося, що артефакт існує саме там, де очікує CI
	@if [ ! -f "$(DIST_DIR)/$(APP_NAME)" ]; then \
		echo "ERROR: Не знайдено артефакт $(DIST_DIR)/$(APP_NAME). Перевір конфіг PyInstaller."; \
		exit 1; \
	fi
	@echo "==> Done. Artifact: $(DIST_DIR)/$(APP_NAME)"

# Повна перебудова з очищенням тимчасових файлів PyInstaller
rebuild: distclean build

# Локальний запуск зібраного артефакту (зручно для швидкої перевірки)
run: build
	@echo "==> Running ./$(DIST_DIR)/$(APP_NAME)"
	@./$(DIST_DIR)/$(APP_NAME)

# Прибирання тимчасових файлів PyInstaller
clean:
	@echo "==> Cleaning intermediate files"
	@rm -rf "$(BUILD_DIR)" *.spec __pycache__

# Повне очищення (у т.ч. артефактів)
distclean: clean
	@echo "==> Removing dist artifacts"
	@rm -rf "$(DIST_DIR)"

# Друк корисної довідки
help:
	@echo "Targets:"
	@echo "  make build        - зібрати псевдобінарник у dist/$(APP_NAME)"
	@echo "  make rebuild      - повна перебудова (distclean + build)"
	@echo "  make run          - запустити зібраний бінарник"
	@echo "  make clean        - прибрати тимчасові файли PyInstaller"
	@echo "  make distclean    - повністю прибрати dist/ і build/"
	@echo "Vars (override via CLI):"
	@echo "  APP_NAME=<name>   - ім'я артефакту (default: $(APP_NAME))"
	@echo "  ENTRYPOINT=<path> - шлях до main .py (default: $(ENTRYPOINT))"
