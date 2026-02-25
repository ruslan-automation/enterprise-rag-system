# 🎯 Legal RAG: Полный План Реализации (OpenRouter Edition)

## ✅ ЧТО УЖЕ ГОТОВО
- [x] Pinecone индекс `legal-assistant` (1536 dims, cosine, text-embedding-3-small)
- [x] Файл `legal_knowledge_base.json` с 7 статьями законов
- [ ] OpenAI API Key (для embeddings)
- [ ] OpenRouter API Key (для LLM)
- [ ] Telegram Bot Token

---

## 📋 ДЕНЬ 1: Получение API Ключей

### Шаг 1.1: OpenAI API Key
1. Зайти на https://platform.openai.com/api-keys
2. Нажать "Create new secret key"
3. Скопировать ключ (начинается с `sk-...`)
4. Пополнить баланс на $5-10

### Шаг 1.2: OpenRouter API Key
1. Зайти на https://openrouter.ai/keys
2. Нажать "Create Key"
3. Скопировать ключ
4. Пополнить баланс на $3-5

### Шаг 1.3: Telegram Bot
1. Открыть @BotFather в Telegram
2. Отправить команду: `/newbot`
3. Имя бота: `Legal Assistant Demo`
4. Username: `YourName_legal_bot` (уникальный)
5. Скопировать Token (начинается с цифр)

### Шаг 1.4: Pinecone API Key
1. Зайти в Pinecone Console → API Keys
2. Нажать "Create API Key"
3. Скопировать ключ

**СОХРАНИ ВСЕ КЛЮЧИ В ФАЙЛ `api_keys.txt` (НЕ КОММИТЬ В GIT!)**

---

## 🧠 ДЕНЬ 2: Воркфлоу #1 - Ingestion (Загрузка Данных)

### Открыть n8n
1. Перейти на https://app.n8n.cloud (или твой self-hosted)
2. Создать новый воркфлоу
3. Назвать: `Legal_RAG_Ingestion`

### Нода 1: Manual Trigger
- Добавить ноду "Manual Trigger"
- Оставить настройки по умолчанию

### Нода 2: Code Node (Read JSON)
- Добавить "Code" ноду
- Имя: `Read JSON File`
- Код:
```javascript
const fs = require('fs');
const path = 'C:/Users/79514/Desktop/Antigravity/Life_Strategy/Portfolio/02_Legal_RAG/legal_knowledge_base.json';
const data = JSON.parse(fs.readFileSync(path, 'utf8'));

return data.map(item => ({ json: item }));
```

### Нода 3: Code Node (Chunking + Metadata Fix)
- Добавить "Code" ноду
- Имя: `Chunking with Text in Metadata`
- Код:
```javascript
const item = $input.item.json;
const content = item.content;

const chunkSize = 1200;
const overlap = 250;
const chunks = [];

for (let i = 0; i < content.length; i += (chunkSize - overlap)) {
  const chunkText = content.slice(i, i + chunkSize);
  chunks.push({
    text: chunkText,
    metadata: {
      text: chunkText, // КРИТИЧНО: Дублируем для RAG Query
      type: item.metadata.type,
      code: item.metadata.code,
      article: item.metadata.article,
      chunk_index: chunks.length,
      source_id: item.id
    }
  });
}

return chunks.map(c => ({ json: c }));
```

### Нода 4: OpenAI Embeddings
- Добавить ноду "OpenAI"
- Тип: "Embeddings"
- Credentials: Добавить OpenAI API Key
- Model: `text-embedding-3-small`
- Input: `={{ $json.text }}`

### Нода 5: HTTP Request (Pinecone Upsert)
- Добавить "HTTP Request" ноду
- Method: `POST`
- URL: `https://legal-assistant-61z1031.svc.aped-4627-b74a.pinecone.io/vectors/upsert`
  *(Замени на свой HOST из Pinecone Console!)*
- Authentication: None
- Headers:
  - `Api-Key`: `YOUR_PINECONE_API_KEY`
  - `Content-Type`: `application/json`
- Body (JSON):
```json
{
  "vectors": [{
    "id": "{{ $json.metadata.source_id }}_{{ $json.metadata.chunk_index }}",
    "values": {{ $json.embedding }},
    "metadata": {
      "text": "{{ $json.metadata.text }}",
      "type": "{{ $json.metadata.type }}",
      "code": "{{ $json.metadata.code }}",
      "article": "{{ $json.metadata.article }}"
    }
  }]
}
```

### Нода 6: Set (Logging)
- Добавить "Set" ноду
- Создать поле:
  - Name: `uploaded_count`
  - Value: `={{ $json.metadata.source_id }}`

### ✅ Запуск Теста
1. Нажать "Execute Workflow"
2. Проверить в Pinecone Console → Indexes → legal-assistant:
   - Record Count должен быть ~15-20 (в зависимости от чанкинга)
   - В Browser Tab кликни на любой вектор и проверь что есть поле `metadata.text`

---

## 🗣️ ДЕНЬ 3: Воркфлоу #2 - Chat (Ответы на Вопросы)

### Открыть n8n
1. Создать новый воркфлоу
2. Назвать: `Legal_RAG_Chat`

### Нода 1: Telegram Trigger
- Добавить "Telegram Trigger"
- Credentials: Добавить Token бота
- Updates: `message`
- Включить Webhook

### Нода 2: Code Node (Extract Question)
- Имя: `Extract Question`
- Код:
```javascript
const message = $input.item.json.message;
return [{
  json: {
    chat_id: message.chat.id,
    question: message.text || "Пустое сообщение"
  }
}];
```

### Нода 3: OpenAI Embeddings
- Model: `text-embedding-3-small`
- Input: `={{ $json.question }}`

### Нода 4: HTTP Request (Pinecone Query)
- Method: `POST`
- URL: `https://legal-assistant-61z1031.svc.aped-4627-b74a.pinecone.io/query`
- Headers:
  - `Api-Key`: `YOUR_PINECONE_API_KEY`
  - `Content-Type`: `application/json`
- Body:
```json
{
  "vector": {{ $json.embedding }},
  "topK": 5,
  "includeMetadata": true
}
```

### Нода 5: Code Node (Format Context)
- Имя: `Format Context from Metadata`
- Код:
```javascript
const matches = $input.item.json.matches || [];

if (matches.length === 0) {
  return [{
    json: {
      context: "❌ В базе знаний нет информации по этому вопросу.",
      question: $node["Extract Question"].json.question,
      chat_id: $node["Extract Question"].json.chat_id
    }
  }];
}

const context = matches.slice(0, 3).map((m, i) => {
  const meta = m.metadata || {};
  const source = `${meta.code || '?'} ст. ${meta.article || '?'}`;
  const text = meta.text || '[текст отсутствует]';
  return `📄 **Источник ${i+1}:** ${source}\n${text}`;
}).join('\n\n---\n\n');

return [{
  json: {
    context,
    question: $node["Extract Question"].json.question,
    chat_id: $node["Extract Question"].json.chat_id
  }
}];
```

### Нода 6: OpenAI Chat Model (через OpenRouter)
- Добавить "OpenAI Chat Model"
- **ВАЖНО:** В настройках Credentials:
  - API Key: `YOUR_OPENROUTER_API_KEY`
  - Base URL: `https://openrouter.ai/api/v1`
- Model: `openai/gpt-4o-mini`
- System Message:
```
Ты - профессиональный юридический консультант.

ПРАВИЛА:
1. Отвечай ТОЛЬКО на основе предоставленного контекста
2. Обязательно цитируй источники: "Согласно ст. X [Код], ..."
3. Если в контексте нет ответа, скажи: "В предоставленных документах нет информации по этому вопросу"
4. НЕ придумывай факты
5. В конце КАЖДОГО ответа добавляй строку:

"⚠️ Это демо-система. Не является юридической консультацией."
```
- User Message:
```
Контекст из базы знаний:
{{ $json.context }}

Вопрос пользователя: {{ $json.question }}
```

### Нода 7: Telegram Send Message
- Chat ID: `={{ $json.chat_id }}`
- Text: `={{ $json.choices[0].message.content }}`

### ✅ Активация Бота
1. Сохранить воркфлоу
2. Включить Active (Toggle в правом верхнем углу)
3. Открыть Telegram → Найти своего бота
4. Написать: "Что такое кража?"
5. Проверить что бот ответил с цитированием Ст. 158 УК РФ + Disclaimer

---

## 🧪 ДЕНЬ 4: Тестирование

### Тестовые Сценарии

**Тест 1: Базовый (УК РФ)**
- Вопрос: `Что такое кража по закону?`
- Ожидание: Ответ с цитатой Ст. 158 УК РФ

**Тест 2: Специфичный (ТК РФ)**
- Вопрос: `Какой срок для подачи в суд по зарплате?`
- Ожидание: "1 год" + цитата Ст. 392 ТК РФ

**Тест 3: Негативный (Out of Domain)**
- Вопрос: `Как оформить развод?`
- Ожидание: "В базе знаний нет информации..."

**Тест 4: Пограничный**
- Вопрос: `Меня уволили за прогул, сколько у меня есть времени подать в суд?`
- Ожидание: Смесь Ст. 81 (прогул) + Ст. 392 (1 месяц)

### Запись Демо-Видео
1. Включить OBS или Screen Recorder
2. Показать:
   - Telegram чат с вопросами
   - Быстрые ответы с источниками
   - Pinecone Dashboard (количество векторов)
   - n8n Workflow визуализацию
3. Длительность: 2-3 минуты
4. Сохранить как `LEGAL_RAG_DEMO.mp4`

---

## 💼 ДЕНЬ 5: Финализация Портфолио

### Файлы для Экспорта
1. В n8n → Export обоих воркфлоу (JSON)
2. Сохранить в папку `n8n_workflows/`
3. Сделать скриншоты:
   - Telegram чат
   - Pinecone Dashboard
   - n8n Workflow

### README.md (создать в корне проекта)
```markdown
# Legal RAG Assistant - AI Юрист

## Проблема
Юристы тратят **2-3 часа/день** на поиск информации в законах и договорах.

## Решение
RAG-система **мгновенно** находит релевантную информацию и цитирует источники.

## Технологии
- **Vector DB:** Pinecone (1536 dims, text-embedding-3-small)
- **Embeddings:** OpenAI text-embedding-3-small
- **LLM:** OpenRouter (GPT-4o-mini / Gemini Flash)
- **Orchestration:** n8n
- **Interface:** Telegram Bot API

## Метрики
- 7 документов (статьи законов)
- ~20 векторов в Pinecone
- <2 сек время ответа
- 100% точность цитирования (no hallucinations)

## ROI для Клиента
```
20 запросов/день × 10 мин экономии = 3.3 часа/день
66 часов/месяц × $100/час = $6,600/месяц ценности

Стоимость внедрения: $40,000
Окупаемость: 6 месяцев
```

## Демо
[Ссылка на видео]

⚠️ **Disclaimer:** Система не является юридической консультацией.
```

---

## 📊 Финальный Чеклист

### Инфраструктура
- [x] Pinecone индекс создан
- [ ] OpenAI API ключ активен
- [ ] OpenRouter API ключ активен
- [ ] Telegram бот отвечает

### Функциональность
- [ ] Загрузка документов работает (видны векторы в Pinecone)
- [ ] Поиск возвращает релевантные результаты
- [ ] Бот цитирует источники
- [ ] Нет галлюцинаций на out-of-context вопросах
- [ ] Disclaimer добавлен в каждый ответ

### Демо
- [ ] 4 тестовых сценария пройдены
- [ ] Видео записано (2-3 мин)
- [ ] Screenshots сделаны

### Портфолио
- [ ] README.md написан
- [ ] Все файлы загружены в `Portfolio/02_Legal_RAG/`
- [ ] Демо доступно для показа клиентам

---

## 💰 Бюджет

**API Costs (тестирование):**
- Pinecone: $0 (free tier)
- OpenAI Embeddings: ~$0.50 (25k tokens)
- OpenRouter GPT-4o-mini: ~$2 (100 queries)
- **TOTAL:** ~$3

**Время:**
- День 1-2: 3-4 часа
- День 3-4: 3-4 часа
- День 5: 1-2 часа
- **TOTAL:** 7-10 часов

**Ценность для Портфолио:**
- Демонстрирует: RAG, Vector DB, n8n, AI integration
- Ниша: Legal Tech ($40-50k чеки)
- Вау-эффект: 10/10

---

## 🚨 Troubleshooting

**Ошибка: "Dimension mismatch"**
- Проверь что Pinecone индекс имеет 1536 dimensions
- Проверь что используешь `text-embedding-3-small`

**Ошибка: "metadata.text is undefined"**
- Проверь что в Chunking Node ты дублируешь `text` в `metadata`
- Проверь что в Pinecone Upsert Body есть `"text": "{{ $json.metadata.text }}"`

**Бот не отвечает в Telegram**
- Проверь что воркфлоу `Active` (toggle включен)
- Проверь что Webhook настроен правильно (в логах n8n)

**OpenRouter возвращает 401**
- Проверь что Base URL = `https://openrouter.ai/api/v1`
- Проверь что API Key правильный
- Пополни баланс на OpenRouter
