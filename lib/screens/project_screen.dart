import 'package:easy_localization/easy_localization.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:flutter/material.dart';
import 'package:planka_app/providers/project_provider.dart';
import 'package:planka_app/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/project_list.dart';

class ProjectScreen extends StatefulWidget {
const ProjectScreen({super.key});

@override
_ProjectScreenState createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> with SingleTickerProviderStateMixin{

  late Animation<double> _animation;
  late AnimationController _animationController;

  @override
  void initState(){

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    final curvedAnimation = CurvedAnimation(curve: Curves.easeInOut, parent: _animationController);
    _animation = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('app_name'.tr()),
        ),
        floatingActionButton: FloatingActionBubble(
          items: <Bubble>[
            // Bubble(
            //   title:"Create Project",
            //   iconColor :Colors.white,
            //   bubbleColor : Colors.indigo,
            //   icon:Icons.create_rounded,
            //   titleStyle: const TextStyle(fontSize: 16 , color: Colors.white),
            //   onPress: () {
            //     _animationController.reverse();
            //
            //     ///Not enough permissions :D
            //     showTopSnackBar(
            //       Overlay.of(context),
            //       const CustomSnackBar.error(
            //         message:
            //         "Permission missing.",
            //       ),
            //     );
            //   },
            // ),
            // Bubble(
            //   title:"Refresh",
            //   iconColor :Colors.white,
            //   bubbleColor : Colors.indigo,
            //   icon:Icons.refresh_rounded,
            //   titleStyle: const TextStyle(fontSize: 16 , color: Colors.white),
            //   onPress: () {
            //     _animationController.reverse();
            //   },
            // ),
            Bubble(
              title:'settings'.tr(),
              iconColor :Colors.white,
              bubbleColor : Colors.indigo,
              icon:Icons.settings,
              titleStyle: const TextStyle(fontSize: 16 , color: Colors.white),
              onPress: () {
                _animationController.reverse();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
            Bubble(
              title:"logout".tr(),
              iconColor :Colors.white,
              bubbleColor : Colors.indigo,
              icon:Icons.logout_rounded,
              titleStyle: const TextStyle(fontSize: 16 , color: Colors.white),
              onPress: () {
                _animationController.reverse();
                _logout(context);
              },
            ),
          ],
          animation: _animation,
          onPress: () => _animationController.isCompleted
              ? _animationController.reverse()
              : _animationController.forward(),
          iconColor: Colors.white,
          iconData: Icons.menu_rounded,
          backGroundColor: Colors.indigo,
        ),
        body: FutureBuilder(
          future: Provider.of<ProjectProvider>(context, listen: false).fetchProjects(),
          builder: (ctx, snapshot) => snapshot.connectionState == ConnectionState.waiting
          ? const Center(child: CircularProgressIndicator())
              : Consumer<ProjectProvider>(
          builder: (ctx, projectProvider, _) => ProjectList(projectProvider.projects),
          ),
        ),
    );
  }

  void _logout(BuildContext context) async {
    try {
      bool success = await Provider.of<AuthProvider>(context, listen: false).logout(context);

      if(success){
        Navigator.of(context).pushReplacementNamed('/login');
      } else{
        debugPrint("Something went wrong, trying to logout.");
      }
    } catch (error) {
      debugPrint(error.toString());
    }
  }
}
