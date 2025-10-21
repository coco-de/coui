# CoUI Flutter - 일반적인 UI 패턴

> **실전에서 자주 사용하는 화면 패턴 모음**

## 목차

1. [로그인/회원가입 화면](#로그인회원가입-화면)
2. [대시보드](#대시보드)
3. [프로필 화면](#프로필-화면)
4. [리스트 화면](#리스트-화면)
5. [상세 화면](#상세-화면)
6. [설정 화면](#설정-화면)
7. [검색 화면](#검색-화면)
8. [폼 화면](#폼-화면)

---

## 로그인/회원가입 화면

### 1. 기본 로그인 화면

```dart
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 로고
                const FlutterLogo(size: 80),
                Gap.v(24),
                
                // 제목
                const Text('로그인').x2Large.bold,
                Gap.v(8),
                const Text('계정에 로그인하세요').muted,
                Gap.v(32),
                
                // 이메일 입력
                TextField(
                  controller: emailController,
                  placeholder: const Text('이메일'),
                  leading: const Icon(Icons.email),
                ),
                Gap.v(16),
                
                // 비밀번호 입력
                TextField(
                  controller: passwordController,
                  placeholder: const Text('비밀번호'),
                  leading: const Icon(Icons.lock),
                  obscureText: true,
                ),
                Gap.v(8),
                
                // 비밀번호 찾기
                Align(
                  alignment: Alignment.centerRight,
                  child: LinkButton(
                    onPressed: () {},
                    child: const Text('비밀번호를 잊으셨나요?'),
                  ),
                ),
                Gap.v(24),
                
                // 로그인 버튼
                PrimaryButton(
                  onPressed: () {
                    // 로그인 로직
                  },
                  child: const Text('로그인'),
                ),
                Gap.v(12),
                
                // 구분선
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text('또는').small.muted,
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                Gap.v(12),
                
                // 소셜 로그인
                OutlineButton(
                  onPressed: () {},
                  leading: const Icon(Icons.g_mobiledata),
                  child: const Text('Google로 계속하기'),
                ),
                Gap.v(24),
                
                // 회원가입 링크
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('계정이 없으신가요?').small,
                    Gap.h(4),
                    LinkButton(
                      onPressed: () {
                        // 회원가입 화면으로 이동
                      },
                      child: const Text('회원가입').small,
                    ),
                  ],
                ),
              ],
            ),
          ).intrinsic(),
        ),
      ),
    );
  }
}
```

### 2. 소셜 로그인 포함 회원가입

```dart
Column(
  children: [
    // 소셜 로그인 버튼들
    Row(
      children: [
        Expanded(
          child: OutlineButton(
            onPressed: () {},
            child: const Icon(Icons.g_mobiledata),
          ),
        ),
        Gap.h(12),
        Expanded(
          child: OutlineButton(
            onPressed: () {},
            child: const Icon(Icons.apple),
          ),
        ),
        Gap.h(12),
        Expanded(
          child: OutlineButton(
            onPressed: () {},
            child: const Icon(Icons.facebook),
          ),
        ),
      ],
    ),
    Gap.v(24),
    
    // 약관 동의
    Checkbox(
      value: agreeTerms,
      onChanged: (v) => setState(() => agreeTerms = v ?? false),
      child: const Text('이용약관 및 개인정보 처리방침에 동의합니다'),
    ),
  ],
)
```

---

## 대시보드

### 1. 통계 카드 대시보드

```dart
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('대시보드'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            const Text('환영합니다!').x3Large.bold,
            Gap.v(8),
            const Text('오늘의 활동을 확인하세요').muted,
            Gap.v(24),
            
            // 통계 카드들
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  title: '총 사용자',
                  value: '1,234',
                  icon: Icons.people,
                  change: '+12%',
                ),
                _buildStatCard(
                  title: '수익',
                  value: '\$45.6K',
                  icon: Icons.attach_money,
                  change: '+8%',
                ),
                _buildStatCard(
                  title: '주문',
                  value: '856',
                  icon: Icons.shopping_cart,
                  change: '+23%',
                ),
                _buildStatCard(
                  title: '방문자',
                  value: '3,421',
                  icon: Icons.visibility,
                  change: '-5%',
                ),
              ],
            ),
            Gap.v(32),
            
            // 최근 활동
            const Text('최근 활동').large.semiBold,
            Gap.v(16),
            Card(
              child: Column(
                children: [
                  _buildActivityItem(
                    '새 주문이 도착했습니다',
                    '5분 전',
                    Icons.shopping_bag,
                  ),
                  const Divider(),
                  _buildActivityItem(
                    '새로운 사용자가 가입했습니다',
                    '1시간 전',
                    Icons.person_add,
                  ),
                  const Divider(),
                  _buildActivityItem(
                    '결제가 완료되었습니다',
                    '2시간 전',
                    Icons.payment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required String change,
  }) {
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title).small.muted,
              Icon(icon, size: 20),
            ],
          ),
          Text(value).x2Large.bold,
          Row(
            children: [
              SecondaryBadge(child: Text(change)),
              Gap.h(4),
              const Text('vs 지난 주').xSmall.muted,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20),
          ),
          Gap.h(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title).semiBold,
                Text(time).small.muted,
              ],
            ),
          ),
          IconButton.ghost(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
```

---

## 프로필 화면

```dart
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        actions: [
          IconButton.ghost(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 프로필 헤더
            Card(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Avatar(
                    initials: Avatar.getInitials('John Doe'),
                    provider: const NetworkImage(
                      'https://i.pravatar.cc/150?img=12',
                    ),
                  ),
                  Gap.v(16),
                  const Text('John Doe').x2Large.bold,
                  Gap.v(4),
                  const Text('john.doe@example.com').muted,
                  Gap.v(16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PrimaryButton(
                        onPressed: () {},
                        child: const Text('프로필 수정'),
                      ),
                      Gap.h(8),
                      OutlineButton(
                        onPressed: () {},
                        child: const Text('공유'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Gap.v(24),
            
            // 통계
            Row(
              children: [
                Expanded(
                  child: Card(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text('123').x2Large.bold,
                        Gap.v(4),
                        const Text('게시물').small.muted,
                      ],
                    ),
                  ),
                ),
                Gap.h(12),
                Expanded(
                  child: Card(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text('1.5K').x2Large.bold,
                        Gap.v(4),
                        const Text('팔로워').small.muted,
                      ],
                    ),
                  ),
                ),
                Gap.h(12),
                Expanded(
                  child: Card(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text('856').x2Large.bold,
                        Gap.v(4),
                        const Text('팔로잉').small.muted,
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Gap.v(24),
            
            // 메뉴 항목들
            Card(
              child: Column(
                children: [
                  _buildMenuItem(Icons.person, '계정 설정', () {}),
                  const Divider(),
                  _buildMenuItem(Icons.notifications, '알림', () {}),
                  const Divider(),
                  _buildMenuItem(Icons.security, '보안', () {}),
                  const Divider(),
                  _buildMenuItem(Icons.help, '도움말', () {}),
                ],
              ),
            ),
            Gap.v(16),
            
            // 로그아웃
            DestructiveButton(
              onPressed: () {},
              child: const Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon),
            Gap.h(16),
            Expanded(child: Text(title).semiBold),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
```

---

## 리스트 화면

### 1. 연락처 리스트

```dart
class ContactListScreen extends StatelessWidget {
  const ContactListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('연락처'),
        actions: [
          IconButton.primary(
            icon: const Icon(Icons.add),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 20,
        separatorBuilder: (context, index) => Gap.v(12),
        itemBuilder: (context, index) {
          return Card(
            child: Row(
              children: [
                Avatar(initials: 'U${index + 1}'),
                Gap.h(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('사용자 ${index + 1}').bold,
                      Text('user${index + 1}@example.com').small.muted,
                    ],
                  ),
                ),
                IconButton.ghost(
                  icon: const Icon(Icons.phone),
                  onPressed: () {},
                ),
                IconButton.ghost(
                  icon: const Icon(Icons.message),
                  onPressed: () {},
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

### 2. 상품 그리드 리스트

```dart
GridView.builder(
  padding: const EdgeInsets.all(16),
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.75,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
  ),
  itemCount: products.length,
  itemBuilder: (context, index) {
    final product = products[index];
    return Card(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Icon(Icons.image, size: 48)),
            ),
          ),
          Gap.v(12),
          
          // 제품명
          Text(product.name).bold,
          Gap.v(4),
          
          // 가격
          Text('\$${product.price}').large.primary,
          Gap.v(12),
          
          // 장바구니 버튼
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              onPressed: () {},
              child: const Text('담기'),
            ),
          ),
        ],
      ),
    );
  },
)
```

---

## 설정 화면

```dart
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool darkMode = false;
  bool locationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('일반').large.semiBold,
            Gap.v(16),
            
            Card(
              child: Column(
                children: [
                  _buildToggleItem(
                    '알림',
                    '푸시 알림을 받습니다',
                    notificationsEnabled,
                    (value) => setState(() => notificationsEnabled = value),
                  ),
                  const Divider(),
                  _buildToggleItem(
                    '다크 모드',
                    '어두운 테마를 사용합니다',
                    darkMode,
                    (value) => setState(() => darkMode = value),
                  ),
                  const Divider(),
                  _buildToggleItem(
                    '위치',
                    '위치 정보를 사용합니다',
                    locationEnabled,
                    (value) => setState(() => locationEnabled = value),
                  ),
                ],
              ),
            ),
            Gap.v(24),
            
            const Text('계정').large.semiBold,
            Gap.v(16),
            
            Card(
              child: Column(
                children: [
                  _buildMenuItem('이메일 변경', () {}),
                  const Divider(),
                  _buildMenuItem('비밀번호 변경', () {}),
                  const Divider(),
                  _buildMenuItem('계정 삭제', () {}, isDestructive: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title).semiBold,
                Gap.v(4),
                Text(subtitle).small.muted,
              ],
            ),
          ),
          Toggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: isDestructive
                  ? Text(title).destructive
                  : Text(title),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
```

---

## 검색 화면

```dart
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final searchController = TextEditingController();
  List<String> searchResults = [];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      // 실제로는 API 호출
      searchResults = List.generate(
        10,
        (index) => '검색 결과 $index: $query',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          placeholder: const Text('검색...'),
          leading: const Icon(Icons.search),
          trailing: IconButton.ghost(
            icon: const Icon(Icons.clear),
            onPressed: () {
              searchController.clear();
              setState(() => searchResults = []);
            },
          ),
          onChanged: _performSearch,
        ),
      ),
      body: searchResults.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search, size: 64),
                  Gap.v(16),
                  const Text('검색어를 입력하세요').muted,
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                return Card(
                  child: Row(
                    children: [
                      const Icon(Icons.article),
                      Gap.h(12),
                      Expanded(
                        child: Text(searchResults[index]),
                      ),
                      IconButton.ghost(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {},
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
```

---

## 폼 화면

```dart
class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  String? selectedCountry;
  bool agreeTerms = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!agreeTerms) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('알림').bold.large,
              Gap.v(16),
              const Text('약관에 동의해주세요'),
              Gap.v(24),
              PrimaryButton(
                child: const Text('확인'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // 폼 제출 로직
    print('Name: ${nameController.text}');
    print('Email: ${emailController.text}');
    print('Country: $selectedCountry');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('정보 입력')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('기본 정보').x2Large.bold,
              Gap.v(24),
              
              const Text('이름').semiBold.small,
              Gap.v(8),
              TextField(
                controller: nameController,
                placeholder: const Text('이름을 입력하세요'),
              ),
              Gap.v(16),
              
              const Text('이메일').semiBold.small,
              Gap.v(8),
              TextField(
                controller: emailController,
                placeholder: const Text('이메일을 입력하세요'),
              ),
              Gap.v(16),
              
              const Text('국가').semiBold.small,
              Gap.v(8),
              Select<String>(
                value: selectedCountry,
                placeholder: const Text('국가를 선택하세요'),
                onChanged: (value) {
                  setState(() => selectedCountry = value);
                },
                items: [
                  SelectItem(value: 'kr', label: const Text('대한민국')),
                  SelectItem(value: 'us', label: const Text('미국')),
                  SelectItem(value: 'jp', label: const Text('일본')),
                ],
              ),
              Gap.v(24),
              
              Checkbox(
                value: agreeTerms,
                onChanged: (value) {
                  setState(() => agreeTerms = value ?? false);
                },
                child: const Text('이용약관에 동의합니다'),
              ),
              Gap.v(32),
              
              PrimaryButton(
                onPressed: _submitForm,
                child: const Text('제출'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 마치며

이 패턴들은 실제 앱 개발에서 자주 사용되는 화면 레이아웃입니다. 각 패턴을 프로젝트에 맞게 수정하여 사용하세요.

**주의사항**:
- 모든 컨트롤러는 `dispose()`에서 해제해야 합니다
- `setState()`를 사용하여 상태를 업데이트하세요
- `Gap`을 사용하여 일관된 간격을 유지하세요
- Text extensions를 활용하여 타이포그래피를 일관되게 유지하세요

