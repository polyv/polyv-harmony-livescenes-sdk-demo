import { HashMap } from '@kit.ArkTS';

class PLVLIFaceManager {
  private faceMap: HashMap<string, Resource> = new HashMap()

  constructor() {
    this.initFaceMap()
  }

  private initFaceMap() {
    this.faceMap.set('[呲牙]', $r('app.media.plvli_face_101'));
    this.faceMap.set('[大笑]', $r('app.media.plvli_face_102'));
    this.faceMap.set('[可爱]', $r('app.media.plvli_face_103'));
    this.faceMap.set('[害羞]', $r('app.media.plvli_face_104'));
    this.faceMap.set('[偷笑]', $r('app.media.plvli_face_105'));
    this.faceMap.set('[再见]', $r('app.media.plvli_face_106'));
    this.faceMap.set('[惊讶]', $r('app.media.plvli_face_107'));
    this.faceMap.set('[哭笑]', $r('app.media.plvli_face_108'));
    this.faceMap.set('[酷]', $r('app.media.plvli_face_109'));
    this.faceMap.set('[奸笑]', $r('app.media.plvli_face_110'));
    this.faceMap.set('[鼓掌]', $r('app.media.plvli_face_111'));
    this.faceMap.set('[大哭]', $r('app.media.plvli_face_112'));
    this.faceMap.set('[敲打]', $r('app.media.plvli_face_113'));
    this.faceMap.set('[吃瓜]', $r('app.media.plvli_face_114'));
    this.faceMap.set('[让我看看]', $r('app.media.plvli_face_115'));
    this.faceMap.set('[按脸哭]', $r('app.media.plvli_face_116'));
    this.faceMap.set('[打哈欠]', $r('app.media.plvli_face_117'));
    this.faceMap.set('[愤怒]', $r('app.media.plvli_face_118'));
    this.faceMap.set('[难过]', $r('app.media.plvli_face_119'));
    this.faceMap.set('[ok]', $r('app.media.plvli_face_120'));
    this.faceMap.set('[爱心]', $r('app.media.plvli_face_121'));
    this.faceMap.set('[加1]', $r('app.media.plvli_face_122'));
    this.faceMap.set('[心碎]', $r('app.media.plvli_face_123'));
    this.faceMap.set('[正确]', $r('app.media.plvli_face_124'));
    this.faceMap.set('[错误]', $r('app.media.plvli_face_125'));
    this.faceMap.set('[满分]', $r('app.media.plvli_face_126'));
    this.faceMap.set('[笔记]', $r('app.media.plvli_face_127'));
    this.faceMap.set('[胜利]', $r('app.media.plvli_face_128'));
    this.faceMap.set('[比心]', $r('app.media.plvli_face_129'));
    this.faceMap.set('[赞]', $r('app.media.plvli_face_130'));
    this.faceMap.set('[蛋糕]', $r('app.media.plvli_face_131'));
    this.faceMap.set('[礼物]', $r('app.media.plvli_face_132'));
    this.faceMap.set('[红包]', $r('app.media.plvli_face_133'));
    this.faceMap.set('[奶茶]', $r('app.media.plvli_face_134'));
    this.faceMap.set('[时钟]', $r('app.media.plvli_face_135'));
    this.faceMap.set('[晚安]', $r('app.media.plvli_face_136'));
    this.faceMap.set('[拍手]', $r('app.media.plvli_face_137'));
    this.faceMap.set('[鲜花]', $r('app.media.plvli_face_138'));
  }

  getFace(faceKey: string): Resource | string {
    if (this.faceMap.hasKey(faceKey)) {
      return this.faceMap.get(faceKey)
    }
    return faceKey
  }
}

export default new PLVLIFaceManager()