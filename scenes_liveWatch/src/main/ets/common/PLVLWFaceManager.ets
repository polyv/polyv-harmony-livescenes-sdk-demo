import { HashMap } from '@kit.ArkTS';

// <editor-fold defaultstate="collapsed" desc="faceMap">
const faceMap = new HashMap<string, Resource>();
faceMap.set('[呲牙]', $r('app.media.plvlw_face_101'));
faceMap.set('[大笑]', $r('app.media.plvlw_face_102'));
faceMap.set('[可爱]', $r('app.media.plvlw_face_103'));
faceMap.set('[害羞]', $r('app.media.plvlw_face_104'));
faceMap.set('[偷笑]', $r('app.media.plvlw_face_105'));
faceMap.set('[再见]', $r('app.media.plvlw_face_106'));
faceMap.set('[惊讶]', $r('app.media.plvlw_face_107'));
faceMap.set('[哭笑]', $r('app.media.plvlw_face_108'));
faceMap.set('[酷]', $r('app.media.plvlw_face_109'));
faceMap.set('[奸笑]', $r('app.media.plvlw_face_110'));
faceMap.set('[鼓掌]', $r('app.media.plvlw_face_111'));
faceMap.set('[大哭]', $r('app.media.plvlw_face_112'));
faceMap.set('[敲打]', $r('app.media.plvlw_face_113'));
faceMap.set('[吃瓜]', $r('app.media.plvlw_face_114'));
faceMap.set('[让我看看]', $r('app.media.plvlw_face_115'));
faceMap.set('[按脸哭]', $r('app.media.plvlw_face_116'));
faceMap.set('[打哈欠]', $r('app.media.plvlw_face_117'));
faceMap.set('[愤怒]', $r('app.media.plvlw_face_118'));
faceMap.set('[难过]', $r('app.media.plvlw_face_119'));
faceMap.set('[ok]', $r('app.media.plvlw_face_120'));
faceMap.set('[爱心]', $r('app.media.plvlw_face_121'));
faceMap.set('[加1]', $r('app.media.plvlw_face_122'));
faceMap.set('[心碎]', $r('app.media.plvlw_face_123'));
faceMap.set('[正确]', $r('app.media.plvlw_face_124'));
faceMap.set('[错误]', $r('app.media.plvlw_face_125'));
faceMap.set('[满分]', $r('app.media.plvlw_face_126'));
faceMap.set('[笔记]', $r('app.media.plvlw_face_127'));
faceMap.set('[胜利]', $r('app.media.plvlw_face_128'));
faceMap.set('[比心]', $r('app.media.plvlw_face_129'));
faceMap.set('[赞]', $r('app.media.plvlw_face_130'));
faceMap.set('[蛋糕]', $r('app.media.plvlw_face_131'));
faceMap.set('[礼物]', $r('app.media.plvlw_face_132'));
faceMap.set('[红包]', $r('app.media.plvlw_face_133'));
faceMap.set('[奶茶]', $r('app.media.plvlw_face_134'));
faceMap.set('[时钟]', $r('app.media.plvlw_face_135'));
faceMap.set('[晚安]', $r('app.media.plvlw_face_136'));
faceMap.set('[拍手]', $r('app.media.plvlw_face_137'));
faceMap.set('[鲜花]', $r('app.media.plvlw_face_138'));

// </editor-fold>

export class PLVLWFaceManager {
  private constructor() {
  }

  static getFace(faceKey: string): Resource | string {
    return faceMap.get(faceKey) ?? faceKey
  }

  static hasFace(faceKey: string): boolean {
    return faceMap.hasKey(faceKey)
  }
}

