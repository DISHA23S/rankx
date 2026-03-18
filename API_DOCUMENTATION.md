# API Documentation

## Overview

QuizMaster uses Supabase as the backend. All API calls are made through the Supabase Flutter SDK with automatic RLS enforcement.

## Base URL
```
https://[your-project].supabase.co
```

## Authentication

All requests require:
- Supabase Anon Key in headers (automatically handled by SDK)
- User session token (handled by Supabase Auth)

## Endpoints Reference

### Authentication

#### Send OTP
```
POST /auth/v1/otp
```
**Parameters:**
- `email` (string) - User email
- `phone` (string, optional) - User phone

**Response:**
```json
{
  "user": {
    "id": "user-uuid",
    "email": "user@example.com"
  }
}
```

#### Verify OTP
```
POST /auth/v1/verify
```
**Parameters:**
- `token_hash` (string) - OTP token
- `type` (string) - "email" or "phone"

### Users

#### Create User Profile
```
POST /rest/v1/users
```
**Body:**
```json
{
  "id": "user-uuid",
  "email": "user@example.com",
  "role": "user",
  "name": "John Doe",
  "phone": "+1234567890"
}
```

#### Get User Profile
```
GET /rest/v1/users?id=eq.user-uuid
```

**Response:**
```json
{
  "id": "user-uuid",
  "email": "user@example.com",
  "role": "user",
  "name": "John Doe",
  "created_at": "2024-01-01T00:00:00Z"
}
```

#### Update User Profile
```
PATCH /rest/v1/users?id=eq.user-uuid
```
**Body:**
```json
{
  "name": "Jane Doe",
  "profile_image": "image-url"
}
```

### Quizzes

#### Create Quiz (Admin Only)
```
POST /rest/v1/quizzes
```
**Body:**
```json
{
  "admin_id": "admin-uuid",
  "title": "Flutter Basics",
  "description": "Learn Flutter fundamentals",
  "category": "Programming",
  "total_questions": 10,
  "duration_seconds": 600,
  "price": 99.99,
  "is_paid": true,
  "difficulty": 2
}
```

#### Get Published Quizzes
```
GET /rest/v1/quizzes?status=eq.published&select=*
```

**Response:**
```json
[
  {
    "id": "quiz-uuid",
    "admin_id": "admin-uuid",
    "title": "Flutter Basics",
    "category": "Programming",
    "total_questions": 10,
    "duration_seconds": 600,
    "status": "published",
    "created_at": "2024-01-01T00:00:00Z"
  }
]
```

#### Get Quiz by ID
```
GET /rest/v1/quizzes?id=eq.quiz-uuid&select=*
```

#### Update Quiz
```
PATCH /rest/v1/quizzes?id=eq.quiz-uuid
```
**Body:**
```json
{
  "title": "Updated Title",
  "description": "Updated description",
  "duration_seconds": 900
}
```

#### Publish Quiz
```
PATCH /rest/v1/quizzes?id=eq.quiz-uuid
```
**Body:**
```json
{
  "status": "published",
  "published_at": "2024-01-01T00:00:00Z"
}
```

#### Delete Quiz
```
DELETE /rest/v1/quizzes?id=eq.quiz-uuid
```

### Questions & Answers

#### Get Questions by Quiz
```
GET /rest/v1/questions?quiz_id=eq.quiz-uuid&select=*
```

#### Create Question
```
POST /rest/v1/questions
```
**Body:**
```json
{
  "quiz_id": "quiz-uuid",
  "question_text": "What is Flutter?",
  "question_number": 1
}
```

#### Get Answers by Question
```
GET /rest/v1/answers?question_id=eq.question-uuid&select=*
```

#### Create Answer
```
POST /rest/v1/answers
```
**Body:**
```json
{
  "question_id": "question-uuid",
  "answer_text": "A mobile framework",
  "answer_number": 1,
  "is_correct": true,
  "explanation": "Flutter is indeed a mobile framework"
}
```

### User Answers (Quiz Taking)

#### Submit Answer
```
POST /rest/v1/user_answers
```
**Body:**
```json
{
  "user_id": "user-uuid",
  "quiz_id": "quiz-uuid",
  "question_id": "question-uuid",
  "selected_answer_id": "answer-uuid",
  "is_correct": true,
  "time_spent_seconds": 45
}
```

#### Get User Quiz Attempts
```
GET /rest/v1/user_answers?user_id=eq.user-uuid&quiz_id=eq.quiz-uuid
```

### User Points

#### Get User Points
```
GET /rest/v1/user_points?user_id=eq.user-uuid
```

**Response:**
```json
{
  "id": "points-uuid",
  "user_id": "user-uuid",
  "daily_points": 250,
  "weekly_points": 1500,
  "total_points": 12500,
  "last_updated": "2024-01-01T00:00:00Z"
}
```

#### Update Points
```
PATCH /rest/v1/user_points?user_id=eq.user-uuid
```
**Body:**
```json
{
  "daily_points": 300,
  "weekly_points": 1600,
  "total_points": 12600
}
```

### Payments

#### Create Payment
```
POST /rest/v1/payments
```
**Body:**
```json
{
  "user_id": "user-uuid",
  "quiz_id": "quiz-uuid",
  "amount": 99.99,
  "payment_method": "card",
  "status": "pending"
}
```

#### Update Payment Status
```
PATCH /rest/v1/payments?id=eq.payment-uuid
```
**Body:**
```json
{
  "status": "completed",
  "transaction_id": "txn-123456",
  "completed_at": "2024-01-01T00:00:00Z"
}
```

#### Get User Payments
```
GET /rest/v1/payments?user_id=eq.user-uuid&order=created_at.desc
```

### Subscriptions

#### Create Subscription
```
POST /rest/v1/subscriptions
```
**Body:**
```json
{
  "user_id": "user-uuid",
  "plan": "monthly",
  "amount": 149.99,
  "start_date": "2024-01-01",
  "end_date": "2024-02-01",
  "is_active": true,
  "payment_id": "payment-uuid"
}
```

#### Get Active Subscription
```
GET /rest/v1/subscriptions?user_id=eq.user-uuid&is_active=eq.true&select=*&limit=1&order=end_date.desc
```

### Agreements

#### Get Active Agreements
```
GET /rest/v1/agreements?is_active=eq.true&select=*
```

#### Accept Agreement
```
POST /rest/v1/user_agreements
```
**Body:**
```json
{
  "user_id": "user-uuid",
  "agreement_id": "agreement-uuid",
  "accepted": true
}
```

#### Check User Agreement Acceptance
```
GET /rest/v1/user_agreements?user_id=eq.user-uuid&agreement_id=eq.agreement-uuid&accepted=eq.true
```

## Query Filters & Options

### Common Filters
```
?id=eq.value          // Equal to
?name=ilike.%pattern% // Case-insensitive like
?age=gt.18            // Greater than
?age=lt.65            // Less than
?status=in.(active,pending) // In list
```

### Select Specific Columns
```
?select=id,name,email
```

### Ordering
```
?order=created_at.desc  // Descending
?order=name.asc         // Ascending
```

### Pagination
```
?offset=10&limit=20
```

## Rate Limits

- **Free Tier**: 50,000 API calls/month
- **Rate**: No per-second limits
- **Concurrent**: 200 connections for realtime

## Error Responses

### 401 Unauthorized
```json
{
  "message": "Unauthorized",
  "code": "PGRST301"
}
```

### 403 Forbidden (RLS Policy)
```json
{
  "message": "new row violates row-level security policy",
  "code": "PGRST204"
}
```

### 400 Bad Request
```json
{
  "message": "Invalid request body",
  "code": "PGRST400"
}
```

### 409 Conflict
```json
{
  "message": "Duplicate key value violates unique constraint",
  "code": "PGRST409"
}
```

## Realtime Subscriptions

### Subscribe to Quiz Changes
```dart
Supabase.instance.client
  .channel('public:quizzes')
  .onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'quizzes',
    callback: (payload) {
      print('Quiz updated: ${payload.newRecord}');
    },
  )
  .subscribe();
```

## SDK Examples

### Using SupabaseService
```dart
final service = SupabaseService();

// Query
final data = await service.query(
  table: 'quizzes',
  filters: {'status': 'published'},
  orderBy: 'created_at',
  ascending: false,
);

// Insert
await service.insert(
  table: 'quizzes',
  data: [
    {
      'admin_id': adminId,
      'title': 'New Quiz',
      // ...
    }
  ],
);

// Update
await service.update(
  table: 'quizzes',
  data: {'status': 'published'},
  columnName: 'id',
  columnValue: quizId,
);

// Delete
await service.delete(
  table: 'quizzes',
  columnName: 'id',
  columnValue: quizId,
);
```

## Best Practices

1. **Always validate user input** before sending to API
2. **Use RLS policies** for data security
3. **Cache frequently accessed data** locally
4. **Handle errors gracefully** with try-catch
5. **Use indexes** on filtered columns
6. **Batch operations** when possible
7. **Monitor API usage** in Supabase dashboard

## Performance Tips

1. Select only needed columns
2. Use filters to reduce data returned
3. Implement pagination for large datasets
4. Use materialized views for complex queries
5. Cache results with GetX or local storage
6. Use database indexes wisely

---

For more details, refer to [Supabase Documentation](https://supabase.com/docs)
