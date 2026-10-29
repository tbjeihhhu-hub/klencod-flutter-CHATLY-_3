
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

const olive = Color(0xFF354B32);
const darkOlive = Color(0xFF263923);
const orange = Color(0xFFF28C28);
const cream = Color(0xFFE9DFC9);
const surface = Color(0xFFF0E7D6);
const muted = Color(0xFF9B9A83);
const ink = Color(0xFF30372A);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ChatlyApp());
}

class ChatlyApp extends StatelessWidget {
  const ChatlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'شاتلي',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: olive,
          surface: cream,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// تحديد حالة المستخدم
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingPage();
        }

        final user = snapshot.data;

        if (user == null) {
          return const AuthPage();
        }

        if (!user.emailVerified) {
          return const VerifyEmailPage();
        }

        return const HomePage();
      },
    );
  }
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: olive),
      ),
    );
  }
}

// تسجيل الدخول وإنشاء الحساب
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLogin = false;
  bool loading = false;
  bool hidePassword = true;

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();
    final username = usernameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      message('أدخل البريد الإلكتروني وكلمة المرور');
      return;
    }

    if (password.length < 6) {
      message('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      return;
    }

    if (!isLogin && (name.isEmpty || username.isEmpty)) {
      message('أدخل اسمك واسم المستخدم');
      return;
    }

    setState(() => loading = true);

    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        final user = FirebaseAuth.instance.currentUser;
        await user?.reload();

        if (user != null && !user.emailVerified) {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            message('يجب تأكيد بريدك الإلكتروني أولاً');
          }
        }
      } else {
        final result =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await result.user?.updateDisplayName(name);
        await result.user?.sendEmailVerification();

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const VerifyEmailPage(),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        message(e.message ?? 'تعذر إكمال العملية');
      }
    } catch (e) {
      if (mounted) {
        message('حدث خطأ، حاول مرة ثانية');
      }
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  InputDecoration fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: olive),
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.chat_bubble_rounded,
                  size: 76,
                  color: orange,
                ),
                const SizedBox(height: 10),
                const Text(
                  'شاتلي',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: olive,
                  ),
                ),
                const Text(
                  'تواصل، شارك، وعِش اللحظة',
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 35),
                Text(
                  isLogin ? 'تسجيل الدخول' : 'إنشاء حساب جديد',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: olive,
                  ),
                ),
                const SizedBox(height: 22),

                if (!isLogin) ...[
                  TextField(
                    controller: nameController,
                    decoration: fieldDecoration(
                      'الاسم الكامل',
                      Icons.person_outline,
                    ),
                  ),
                  const SizedBox(height: 13),
                  TextField(
                    controller: usernameController,
                    decoration: fieldDecoration(
                      'اسم المستخدم',
                      Icons.alternate_email,
                    ),
                  ),
                  const SizedBox(height: 13),
                ],

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: fieldDecoration(
                    'البريد الإلكتروني',
                    Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 13),

                TextField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  decoration: fieldDecoration(
                    'كلمة المرور',
                    Icons.lock_outline,
                  ).copyWith(
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => hidePassword = !hidePassword);
                      },
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: olive,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: loading ? null : submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: olive,
                      foregroundColor: cream,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: cream)
                        : Text(
                            isLogin ? 'دخول' : 'إنشاء الحساب',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                TextButton(
                  onPressed: () {
                    setState(() => isLogin = !isLogin);
                  },
                  child: Text(
                    isLogin
                        ? 'ما عندك حساب؟ أنشئ حساب جديد'
                        : 'عندك حساب؟ سجل دخول',
                    style: const TextStyle(color: olive),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// تأكيد البريد الإلكتروني
class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool loading = false;

  Future<void> checkEmail() async {
    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لم يتم تأكيد البريد بعد'),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر التحقق من البريد')),
        );
      }
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> resendEmail() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال رسالة تأكيد جديدة'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر إرسال الرسالة')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.mark_email_read_outlined,
                size: 85,
                color: orange,
              ),
              const SizedBox(height: 20),
              const Text(
                'أكد بريدك الإلكتروني',
                style: TextStyle(
                  color: olive,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'افتح رسالة التأكيد التي وصلتك على بريدك واضغط رابط التأكيد، ثم ارجع إلى شاتلي.',
                textAlign: TextAlign.center,
                style: TextStyle(color: ink, height: 1.6),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : checkEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: olive,
                    foregroundColor: cream,
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: cream)
                      : const Text('تحققت من البريد'),
                ),
              ),
              TextButton(
                onPressed: resendEmail,
                child: const Text(
                  'إعادة إرسال رسالة التأكيد',
                  style: TextStyle(color: olive),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AuthGate(),
                    ),
                    (route) => false,
                  );
                },
                child: const Text(
                  'العودة لتسجيل الدخول',
                  style: TextStyle(color: muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// الصفحة الرئيسية
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  final pages = const [
    ChatsTab(),
    StoriesTab(),
    PostsTab(),
    ProfileTab(),
  ];

  final titles = const [
    'الدردشات',
    'القصص',
    'المنشورات',
    'حسابي',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: olive,
        foregroundColor: cream,
        title: const Text(
          'شاتلي',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: surface,
        indicatorColor: olive.withOpacity(0.15),
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'الدردشات',
          ),
          NavigationDestination(
            icon: Icon(Icons.circle_outlined),
            selectedIcon: Icon(Icons.circle),
            label: 'القصص',
          ),
          NavigationDestination(
            icon: Icon(Icons.dynamic_feed_outlined),
            selectedIcon: Icon(Icons.dynamic_feed),
            label: 'المنشورات',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}

// تبويب الدردشات
class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  static const people = [
    ['سارة محمد', 'هلا شلونك؟', '10:30'],
    ['علي حسن', 'وصلت الرسالة', '09:45'],
    ['نور أحمد', 'نشوفك باچر', 'أمس'],
    ['أحمد كريم', 'تمام حبيبي', 'أمس'],
    ['زينب علي', 'شكراً جزيلاً', 'أمس'],
    ['محمد حيدر', 'وينك؟', 'الاثنين'],
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'آخر المحادثات',
          style: TextStyle(
            color: olive,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        for (final person in people)
          Card(
            color: surface,
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: olive,
                child: Text(
                  person[0][0],
                  style: const TextStyle(color: cream),
                ),
              ),
              title: Text(
                person[0],
                style: const TextStyle(
                  color: ink,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                person[1],
                style: const TextStyle(color: muted),
              ),
              trailing: Text(
                person[2],
                style: const TextStyle(color: muted, fontSize: 11),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(name: person[0]),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// تبويب القصص
class StoriesTab extends StatelessWidget {
  const StoriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_stories_outlined, size: 65, color: olive),
          SizedBox(height: 12),
          Text(
            'القصص',
            style: TextStyle(
              fontSize: 23,
              color: olive,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'ستظهر قصص أصدقائك هنا',
            style: TextStyle(color: muted),
          ),
        ],
      ),
    );
  }
}

// تبويب المنشورات
class PostsTab extends StatelessWidget {
  const PostsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.dynamic_feed_outlined, size: 65, color: olive),
          SizedBox(height: 12),
          Text(
            'المنشورات',
            style: TextStyle(
              fontSize: 23,
              color: olive,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'مساحة لمشاركة لحظاتك وأفكارك',
            style: TextStyle(color: muted),
          ),
        ],
      ),
    );
  }
}

// تبويب الحساب
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundColor: olive,
              child: Icon(
                Icons.person,
                size: 55,
                color: cream,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              user?.displayName ?? 'مستخدم شاتلي',
              style: const TextStyle(
                fontSize: 22,
                color: olive,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              user?.email ?? '',
              style: const TextStyle(color: muted),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('تسجيل الخروج'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: olive,
                  side: const BorderSide(color: olive),
                  padding: const EdgeInsets.all(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// صفحة المحادثة التجريبية
class ChatPage extends StatefulWidget {
  final String name;

  const ChatPage({super.key, required this.name});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final controller = TextEditingController();
  final messages = <String>[];

  void sendMessage() {
    final text = controller.text.trim();

    if (text.isEmpty) return;

    setState(() {
      messages.add(text);
      controller.clear();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: olive,
        foregroundColor: cream,
        title: Text(widget.name),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: olive,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      messages[index],
                      style: const TextStyle(color: cream),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            color: surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالة...',
                      filled: true,
                      fillColor: cream,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                IconButton(
                  onPressed: sendMessage,
                  icon: const Icon(
                    Icons.send_rounded,
                    color: olive,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
