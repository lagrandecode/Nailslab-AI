import '../models/nail_style.dart';

/// Builds photorealistic nail-only edit prompts for OpenAI image edits.
abstract final class NailPromptBuilder {
  static String build(NailStyle style) {
    return '''
CRITICAL: This is a surgical nail-only edit. Change ONLY the fingernail polish and nail art on the existing five nail plates. Do NOT change the hand, fingers, skin, palm, wrist, pose, or background in any way.

WHAT TO CHANGE (nail plates only):
- Apply this manicure to the fingernails only: ${style.prompt}
- Nail tip shape on the existing nails: ${style.shape}
- Finish on nails only: luxury gel polish, high-gloss shine, flashy salon-quality nail art

WHAT MUST STAY IDENTICAL (zero changes):
- Hand shape, finger length, finger thickness, knuckles, joints, and anatomy
- Skin tone, skin texture, pores, wrinkles, veins, and all skin on fingers and palm
- Palm lines, wrist, hand pose, and finger positions
- Background, lighting, shadows on the hand, exposure, and camera angle
- Every pixel of the hand except the colored nail plate surface on each finger

The output must look like the exact same photograph with only the nail polish/design replaced. The hand must be pixel-identical to the input. No smoothing skin, no reshaping fingers, no beauty filter, no CGI.

Repeat: nails only. Hand unchanged. Background unchanged.
'''.trim();
  }
}
