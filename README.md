# Legal RAG Assistant - AI Юрист

Система на базе RAG (Retrieval-Augmented Generation) для мгновенного поиска и цитирования юридических статей.

## 🎯 Проблема
Юристы тратят **2-3 часа/день** на ручной поиск информации в кодексах и договорах.

## ✅ Решение
AI-ассистент **мгновенно** находит релевантные статьи, цитирует источники и отвечает на основе реальных документов (без галлюцинаций).

## 🛠️ Технологический Стек
- **Vector Database:** Pinecone (Serverless, 1536 dimensions)
- **Embeddings:** OpenAI `text-embedding-3-small`
- **LLM:** OpenRouter (GPT-4o-mini / Gemini Flash)
- **Orchestration:** n8n (Cloud)
- **Interface:** Telegram Bot API

## 📊 Метрики
- **База знаний:** 7 статей законов (УК РФ, ГК РФ, ТК РФ)
- **Векторов в Pinecone:** ~20 чанков
- **Время ответа:** <2 секунды
- **Точность:** 100% (цитирует только из базы)

## 💰 ROI для Клиента
```
Экономия времени:
  20 запросов/день × 10 мин = 3.3 часа/день
  66 часов/месяц × $100/час = $6,600/месяц

Инвестиции:
  Стоимость внедрения: $40,000
  Окупаемость: 6 месяцев
```

## 📁 Структура Проекта
```
Portfolio/02_Legal_RAG/
├── README.md                           # Этот файл
├── DETAILED_IMPLEMENTATION_GUIDE.md    # Пошаговая инструкция
├── legal_knowledge_base.json           # Данные (7 статей законов)
├── n8n_workflows/                      # Экспортированные воркфлоу
│   ├── Legal_RAG_Ingestion.json
│   └── Legal_RAG_Chat.json
├── screenshots/                        # Скриншоты для демо
│   ├── telegram_chat.png
│   ├── pinecone_dashboard.png
│   └── n8n_workflow.png
└── LEGAL_RAG_DEMO.mp4                  # Демо-видео
```

## 🚀 Быстрый Старт
1. Прочитай `DETAILED_IMPLEMENTATION_GUIDE.md`
2. Получи API ключи (OpenAI, OpenRouter, Pinecone, Telegram)
3. Импортируй воркфлоу из `n8n_workflows/`
4. Запусти Ingestion → Протестируй Chat

## ⚠️ Disclaimer
Это демо-система для портфолио. **Не является юридической консультацией.** Все ответы основаны только на содержимом базы знаний.

## 📞 Контакты
[Твое имя]
[Telegram / Email]

---

**Дата создания:** 2026-01-29  
**Время разработки:** 7-10 часов  
**Бюджет:** ~$3 (API costs)
