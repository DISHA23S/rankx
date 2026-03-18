import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  late SupabaseClient _client;
  bool _initialized = false;

  SupabaseService._internal() {
    // Initialize client when service is created
    _client = Supabase.instance.client;
    _initialized = true;
  }

  factory SupabaseService() {
    return _instance;
  }

  SupabaseClient get client {
    if (!_initialized || _client == null) {
      _client = Supabase.instance.client;
      _initialized = true;
    }
    return _client;
  }

  bool get isInitialized => _initialized && Supabase.instance.client != null;

  // Auth Methods - OTP
  Future<void> signInWithOtp({
    required String email,
    required String phone,
    bool isEmail = true,
  }) async {
    if (isEmail) {
      await _client.auth.signInWithOtp(email: email);
    } else {
      await _client.auth.signInWithOtp(phone: phone);
    }
  }

  Future<void> verifyOtp({
    required String email,
    required String phone,
    required String token,
  }) async {
    await _client.auth.verifyOTP(
      email: email.isNotEmpty ? email : null,
      phone: phone.isNotEmpty ? phone : null,
      token: token,
      type: email.isNotEmpty ? OtpType.email : OtpType.sms,
    );
  }

  // Auth Methods - Password
  Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> sendPasswordResetEmail({
    required String email,
    String? redirectUrl,
  }) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: redirectUrl,
    );
  }

  Future<void> updateUserPasswordHash({
    required String userId,
    required String passwordHash,
  }) async {
    await _client.from('users').update({
      'password_hash': passwordHash,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }

  // User Profile Methods
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    // Use maybeSingle to avoid throwing when no row exists
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  Future<Map<String, dynamic>?> getUserProfileByEmail(String email) async {
    final response = await _client
        .from('users')
        .select()
        .eq('email', email)
        .maybeSingle();
    return response;
  }

  Future<Map<String, dynamic>?> getUserPointsByUserId(String userId) async {
    final response = await _client
        .from('user_points')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return response;
  }

  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String role,
    String? name,
    String? phone,
    String? passwordHash,
  }) async {
    // If a profile already exists (by id or email), update it instead of inserting
    final existingById = await _client.from('users').select().eq('id', userId).maybeSingle();
    if (existingById != null) {
      await _client.from('users').update({
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (passwordHash != null) 'password_hash': passwordHash,
        'role': role,
        'email_verified': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      return;
    }

    // If no profile by id, check by email to avoid duplicate email constraint
    final existingByEmail = await _client.from('users').select().eq('email', email).maybeSingle();
    if (existingByEmail != null) {
      // Update the existing profile to set the id if missing and update fields
      await _client.from('users').update({
        'id': userId,
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (passwordHash != null) 'password_hash': passwordHash,
        'role': role,
        'email_verified': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('email', email);
      return;
    }

    // No existing profile: insert new row
    await _client.from('users').insert({
      'id': userId,
      'email': email,
      'phone': phone,
      if (passwordHash != null) 'password_hash': passwordHash,
      'role': role,
      'name': name,
      'email_verified': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? phone,
    String? profileImage,
  }) async {
    await _client.from('users').update({
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (profileImage != null) 'profile_image': profileImage,
    }).eq('id', userId);
  }

  // Generic Query Methods
  Future<List<Map<String, dynamic>>> query({
    required String table,
    String? select,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = false,
    int? limit,
  }) async {
    dynamic queryBuilder = _client.from(table).select(select ?? '*');

    filters?.forEach((key, value) {
      queryBuilder = queryBuilder.eq(key, value);
    });

    if (orderBy != null) {
      queryBuilder = queryBuilder.order(orderBy, ascending: ascending);
    }

    if (limit != null) {
      queryBuilder = queryBuilder.limit(limit);
    }

    return await queryBuilder;
  }

  Future<Map<String, dynamic>> querySingle({
    required String table,
    String? select,
    required Map<String, dynamic> filters,
  }) async {
    dynamic queryBuilder = _client.from(table).select(select ?? '*');

    filters.forEach((key, value) {
      queryBuilder = queryBuilder.eq(key, value);
    });

    return await queryBuilder.single();
  }

  Future<List<Map<String, dynamic>>> insert({
    required String table,
    required List<Map<String, dynamic>> data,
  }) async {
    return await _client.from(table).insert(data).select();
  }

  Future<void> update({
    required String table,
    required Map<String, dynamic> data,
    required String columnName,
    required dynamic columnValue,
  }) async {
    await _client.from(table).update(data).eq(columnName, columnValue);
  }

  Future<void> delete({
    required String table,
    required String columnName,
    required dynamic columnValue,
  }) async {
    await _client.from(table).delete().eq(columnName, columnValue);
  }

  // Realtime Subscription
  RealtimeChannel subscribe({
    required String table,
    required Function(Map<String, dynamic>) callback,
  }) {
    return _client
        .channel('public:$table')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          callback: (payload) {
            callback(payload.newRecord);
          },
        )
        .subscribe();
  }

  void unsubscribe(RealtimeChannel channel) {
    _client.removeChannel(channel);
  }
}
