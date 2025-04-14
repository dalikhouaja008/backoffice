import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flareline/core/injection/injection.dart';
import 'package:flareline/presentation/bloc/login/login_bloc.dart';
import 'package:flareline/presentation/bloc/login/login_state.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flareline_uikit/components/forms/outborder_text_form_field.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/flutter_gen/app_localizations.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:toastification/toastification.dart';

class SignInWidget extends StatefulWidget {

const SignInWidget({super.key});
  @override
  State<SignInWidget> createState() => _SignInWidgetState();
}

class _SignInWidgetState extends State<SignInWidget> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn(BuildContext context, LoginBloc bloc) {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validation basique
    if (email.isEmpty) {
      _showError('L\'email est requis', context);
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showError('Format d\'email invalide', context);
      return;
    }
    if (password.isEmpty) {
      _showError('Le mot de passe est requis', context);
      return;
    }

    // Envoyer l'événement de login
    print('[2025-04-13 13:24:37] 🚀 Tentative de connexion'
        '\n└─ Email: $email');

    bloc.add(LoginRequested(email, password));
  }

  void _signInWithGoogle(BuildContext context) {
    _showInfo('Connexion avec Google non implémentée', context);
  }

  void _signInWithGithub(BuildContext context) {
    _showInfo('Connexion avec GitHub non implémentée', context);
  }

  void _showError(String message, BuildContext context) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      title: Text('Erreur'),
      description: Text(message),
      autoCloseDuration: const Duration(seconds: 4),
    );
  }

  void _showInfo(String message, BuildContext context) {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.fillColored,
      title: Text('Information'),
      description: Text(message),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LoginBloc>(
      create: (_) => getIt<LoginBloc>(),
      child: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            print('[2025-04-13 13:35:40] ✅ Connexion réussie'
                '\n└─ Username: ${state.user.username}');

            // Redirection vers la page principale après connexion réussie
             Navigator.of(context).pushReplacementNamed(state.initialRoute);

            // Notification à l'utilisateur
            toastification.show(
              context: context,
              type: ToastificationType.success,
              style: ToastificationStyle.fillColored,
              title: Text('Connexion réussie'),
              description: Text('Bienvenue, ${state.user.username}!'),
              autoCloseDuration: const Duration(seconds: 3),
            );
          } else if (state is LoginFailure) {
            print('[2025-04-13 13:35:40] ❌ Échec de connexion'
                '\n└─ Error: ${state.error}');

            // Notification d'erreur à l'utilisateur
            toastification.show(
              context: context,
              type: ToastificationType.error,
              style: ToastificationStyle.fillColored,
              title: Text('Échec de connexion'),
              description: Text(state.error),
              autoCloseDuration: const Duration(seconds: 5),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            body: ResponsiveBuilder(
              builder: (context, sizingInformation) {
                if (sizingInformation.deviceScreenType ==
                    DeviceScreenType.desktop) {
                  return Center(
                    child: _contentDesktopWidget(context, state),
                  );
                }
                return _contentMobileWidget(context, state);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _contentDesktopWidget(BuildContext context, LoginState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CommonCard(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.symmetric(vertical: 100),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(
                child: Column(
              children: [
                Text(
                  AppLocalizations.of(context)!.appName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.slogan),
                const SizedBox(height: 16),
                SizedBox(
                  width: 350,
                  child: SvgPicture.asset('assets/signin/main.svg',
                      semanticsLabel: ''),
                )
              ],
            )),
            const VerticalDivider(
              width: 1,
              color: GlobalColors.background,
            ),
            Expanded(
              child: _signInFormWidget(context, state),
            )
          ]),
        )
      ],
    );
  }

  Widget _contentMobileWidget(BuildContext context, LoginState state) {
    return CommonCard(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: _signInFormWidget(context, state));
  }

  Widget _signInFormWidget(BuildContext context, LoginState state) {
    final bool isLoading = state is LoginLoading;
    final bloc = BlocProvider.of<LoginBloc>(context);

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.signIn,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),

            // Champ Email
            OutBorderTextFormField(
              labelText: AppLocalizations.of(context)!.email,
              hintText: AppLocalizations.of(context)!.emailHint,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value!.isEmpty || !value.contains('@')) {
                  return 'Veuillez entrer une adresse email valide';
                }
                return null;
              },
              suffixWidget: SvgPicture.asset(
                'assets/signin/email.svg',
                width: 22,
                height: 22,
              ),
              controller: _emailController,
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),

            // Champ Mot de passe
            OutBorderTextFormField(
              obscureText: true,
              labelText: AppLocalizations.of(context)!.password,
              hintText: AppLocalizations.of(context)!.passwordHint,
              keyboardType: TextInputType.visiblePassword,
              validator: (value) {
                if (value!.isEmpty || value.length < 6) {
                  return 'Le mot de passe doit comporter au moins 6 caractères';
                }
                return null;
              },
              suffixWidget: SvgPicture.asset(
                'assets/signin/lock.svg',
                width: 22,
                height: 22,
              ),
              controller: _passwordController,
              enabled: !isLoading,
            ),
            const SizedBox(height: 20),

            // Bouton de connexion - adapté selon votre ButtonWidget
            ButtonWidget(
              type: ButtonType.primary.type,
              btnText: AppLocalizations.of(context)!.signIn,
              // Adaptez ces propriétés en fonction de votre ButtonWidget
              onTap: isLoading ? null : () => _signIn(context, bloc),
              // Si votre ButtonWidget a d'autres propriétés comme disabled, loading, etc.,
              // utilisez-les appropriément:
              // disabled: isLoading,
              // loading: isLoading,
            ),

            // Reste du formulaire
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                    child: Divider(
                  height: 1,
                  color: GlobalColors.border,
                )),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(AppLocalizations.of(context)!.or),
                ),
                const Expanded(
                    child: Divider(
                  height: 1,
                  color: GlobalColors.border,
                )),
              ],
            ),
            const SizedBox(height: 20),
            ButtonWidget(
              color: Colors.white,
              borderColor: GlobalColors.border,
              iconWidget: SvgPicture.asset(
                'assets/brand/brand-01.svg',
                width: 25,
                height: 25,
              ),
              btnText: AppLocalizations.of(context)!.signInWithGoogle,
              onTap: isLoading ? null : () => _signInWithGoogle(context),
            ),
            const SizedBox(height: 20),
            ButtonWidget(
              color: Colors.white,
              borderColor: GlobalColors.border,
              iconWidget: SvgPicture.asset(
                'assets/brand/brand-03.svg',
                width: 25,
                height: 25,
              ),
              btnText: AppLocalizations.of(context)!.signInWithGithub,
              onTap: isLoading ? null : () => _signInWithGithub(context),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppLocalizations.of(context)!.dontHaveAccount),
                InkWell(
                  onTap: isLoading
                      ? null
                      : () => Navigator.of(context).popAndPushNamed('/signUp'),
                  child: Text(
                    AppLocalizations.of(context)!.signUp,
                    style: const TextStyle(color: Colors.blue),
                  ),
                )
              ],
            )
          ],
        ));
  }
}
