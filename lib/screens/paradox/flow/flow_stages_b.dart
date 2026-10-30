part of '../paradox_flow_screen.dart';

class _IdentityStage extends StatelessWidget {
  final TextEditingController nickCtrl;
  final String avatarId;
  final MpRole role;
  final VoidCallback onEnterVoid;
  final double sf;
  const _IdentityStage({
    super.key,
    required this.nickCtrl,
    required this.avatarId,
    required this.role,
    required this.onEnterVoid,
    required this.sf,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24 * sf),
      child: Column(
        children: [
          Container(
            width: 110 * sf,
            height: 110 * sf,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFB388FF).withValues(alpha: 0.6),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: FramedAvatar(id: avatarId, size: 110 * sf, radius: 16),
          ),
          SizedBox(height: 24 * sf),
          TextField(
            controller: nickCtrl,
            maxLength: 20,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22 * sf, fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              hintText: 'Your name',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontWeight: FontWeight.w600,
              ),
              counterStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFB388FF)),
              ),
            ),
          ),
          SizedBox(height: 12 * sf),
          GoopText(
            role == MpRole.main
                ? 'You will host as THE PARADOX'
                : 'You will join as THE CULTIST',
            style: TextStyle(
              fontSize: 11 * sf,
              letterSpacing: 1.2,
              color: Colors.white.withValues(alpha: 0.45),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 36 * sf),
          GestureDetector(
            onTap: onEnterVoid,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 18 * sf),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF4A148C)],
                ),
                border: Border.all(
                  color: const Color(0xFFB388FF).withValues(alpha: 0.8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: GoopText(
                'ENTER THE VOID',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: FontSizes.titleSmall * sf,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoidStage extends StatelessWidget {
  final String avatarId;
  final String nickname;
  final bool seeking;
  final VoidCallback onCancel;
  final Animation<double> pulse;
  final double sf;
  const _VoidStage({
    super.key,
    required this.avatarId,
    required this.nickname,
    required this.seeking,
    required this.onCancel,
    required this.pulse,
    required this.sf,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28 * sf),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: pulse,
              builder:
                  (_, child) => Container(
                    width: 120 * sf,
                    height: 120 * sf,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF7C4DFF,
                          ).withValues(alpha: 0.2 + pulse.value * 0.3),
                          blurRadius: 30 + pulse.value * 20,
                          spreadRadius: 4 + pulse.value * 6,
                        ),
                      ],
                    ),
                    child: child,
                  ),
              child: FramedAvatar(
                id: avatarId,
                size: double.infinity,
                radius: 60,
              ),
            ),
            SizedBox(height: 14 * sf),
            GoopText(
              nickname,
              style: TextStyle(
                fontSize: 15 * sf,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            SizedBox(height: 36 * sf),
            SizedBox(
              width: 26 * sf,
              height: 26 * sf,
              child: const CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFFB388FF),
              ),
            ),
            SizedBox(height: 16 * sf),
            GoopText(
              'Seeking partner through the Void…',
              style: TextStyle(
                fontSize: 13 * sf,
                color: Colors.white.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 8 * sf),
            GoopText(
              'Keep both apps open — the link forms on its own.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11 * sf,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
            SizedBox(height: 36 * sf),
            TextButton(
              onPressed: onCancel,
              child: GoopText(
                'CANCEL',
                style: TextStyle(
                  fontSize: 12 * sf,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LobbyStage extends StatelessWidget {
  final MpSession session;
  final VoidCallback onStartRun;
  final double sf;
  const _LobbyStage({
    super.key,
    required this.session,
    required this.onStartRun,
    required this.sf,
  });

  @override
  Widget build(BuildContext context) {
    final isMain = session.myRole == MpRole.main;
    return SingleChildScrollView(
      padding: EdgeInsets.all(24 * sf),
      child: Column(
        children: [
          // Run title + session number
          GoopText(
            session.runTitle.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: FontSizes.titleLarge * sf,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
              color: const Color(0xFFB388FF),
            ),
          ),
          SizedBox(height: 4 * sf),
          GoopText(
            'SESSION #${session.sessionNumber}',
            style: TextStyle(
              fontSize: 12 * sf,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: 30 * sf),
          // Both players side by side
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LobbyPortrait(
                avatarId: session.avatarId,
                name: session.myNickname,
                role: session.myRole == MpRole.main ? 'MAIN' : 'SIDEKICK',
                color: const Color(0xFF7C4DFF),
                sf: sf,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16 * sf),
                child: const Icon(
                  Icons.link_rounded,
                  color: Color(0xFF00E676),
                  size: 30,
                ),
              ),
              _LobbyPortrait(
                avatarId: session.peerAvatarId,
                name: session.peerNickname ?? 'Partner',
                role: session.myRole == MpRole.main ? 'SIDEKICK' : 'MAIN',
                color: const Color(0xFF26C6DA),
                sf: sf,
              ),
            ],
          ),
          SizedBox(height: 40 * sf),
          if (isMain)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                foregroundColor: Colors.white,
                minimumSize: Size.fromHeight(56 * sf),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onStartRun,
              child: GoopText(
                'START RUN',
                style: TextStyle(
                  fontSize: FontSizes.titleSmall * sf,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            )
          else
            Column(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF26C6DA),
                  ),
                ),
                SizedBox(height: 12 * sf),
                GoopText(
                  'Waiting to start…',
                  style: TextStyle(
                    fontSize: 13 * sf,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LobbyPortrait extends StatelessWidget {
  final String avatarId;
  final String name;
  final String role;
  final Color color;
  final double sf;
  const _LobbyPortrait({
    required this.avatarId,
    required this.name,
    required this.role,
    required this.color,
    required this.sf,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96 * sf,
          height: 96 * sf,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 18),
            ],
          ),
          child: FramedAvatar(id: avatarId, size: double.infinity, radius: 14),
        ),
        SizedBox(height: 10 * sf),
        GoopText(
          name,
          style: TextStyle(
            fontSize: 14 * sf,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        SizedBox(height: 2 * sf),
        GoopText(
          role,
          style: TextStyle(
            fontSize: 10 * sf,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
