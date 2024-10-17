import { curves } from '@kit.ArkUI'
import { util } from '@kit.ArkTS'
import { PLVChatroomManager, PLVLiveSceneSDK, PLVTextUtils, PLVUtils } from '@polyvharmony/live-scenes-sdk'

const TAG = '[PLVLILikeIconView]'

@Preview
@Component
export struct PLVLILikeIconView {
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  @State chatroomManager: PLVChatroomManager | undefined = this.sdk?.chatroomManager
  @State iconScale: number = 1
  @State likeIconAnimationParams: LikeIconAnimationParam[] = []

  aboutToAppear(): void {
    this.onChatData()
  }

  build() {
    Stack() {
      Column() {
        Image($r('app.media.plvli_chatroom_btn_like'))
          .width(34)
          .height(34)
          .scale({ x: this.iconScale, y: this.iconScale })
          .draggable(false)
          .onClick(() => {
            this.iconScale = 1.2
            this.chatroomManager?.likes(1)
          })
          .animation({
            duration: 60,
            curve: Curve.Sharp,
            iterations: 2,
            playMode: PlayMode.Alternate,
            onFinish: () => {
              this.iconScale = 1
            }
          })

        Text(PLVTextUtils.toWString(this.chatroomManager?.likesCount))
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(1)
          .width(68)
          .fontSize(12)
          .margin({ top: 2 })
          .textAlign(TextAlign.Center)
          .fontColor('#ffffff')
      }
      .alignItems(HorizontalAlign.Center)
      .zIndex(99)

      ForEach(this.likeIconAnimationParams, (data: LikeIconAnimationParam, index) => {
        LikeIconAnimationView({ data: data, likeIconAnimationParams: this.likeIconAnimationParams })
          .zIndex(-99)
      }, (data: LikeIconAnimationParam, index) => data.id)
    }
    .width(34)
  }

  onChatData() {
    this.chatroomManager?.eventNotify.on('likes_count', async (arg: number) => {
      const addedCount = arg - this.chatroomManager!.likesCount
      this.chatroomManager!.likesCount = arg
      // 每次最多添加5个点赞动画
      for (let i = 0; i < Math.min(5, addedCount); i++) {
        this.likeIconAnimationParams.push(new LikeIconAnimationParam())
        if (i < (Math.min(5, addedCount) - 1)) {
          await PLVUtils.delay(200)
        }
      }
    }, this)
  }
}

@Preview
@Component
export struct LikeIconAnimationView {
  @ObjectLink data: LikeIconAnimationParam
  @Link likeIconAnimationParams: LikeIconAnimationParam[]

  build() {
    Image(this.data.icon)
      .width(this.data.width)
      .height(this.data.height)
      .opacity(this.data.opacity)
      .rotate({ z: 1, angle: this.data.rotateZ })
      .scale({ x: this.data.scale, y: this.data.scale })
      .translate({ x: this.data.translateX, y: this.data.translateY })
      .draggable(false)
      .onAppear(() => {
        this.data.start()
      })
      .animation({
        duration: 1200,
        curve: curves.cubicBezierCurve(0.0, 0.0, 1.0, 1.0),
        onFinish: () => {
          this.likeIconAnimationParams.shift()
        }
      })
  }
}

@Observed
export class LikeIconAnimationParam {
  static readonly LIKE_ICON: Resource[] = [
    $r('app.media.plvli_chatroom_btn_like_1'),
    $r('app.media.plvli_chatroom_btn_like_2'),
    $r('app.media.plvli_chatroom_btn_like_3'),
    $r('app.media.plvli_chatroom_btn_like_4'),
    $r('app.media.plvli_chatroom_btn_like_5'),
    $r('app.media.plvli_chatroom_btn_like_6'),
    $r('app.media.plvli_chatroom_btn_like_7'),
    $r('app.media.plvli_chatroom_btn_like_8'),
    $r('app.media.plvli_chatroom_btn_like_9'),
    $r('app.media.plvli_chatroom_btn_like_10'),
  ]
  id: string = util.generateRandomUUID(true)
  icon: Resource = LikeIconAnimationParam.LIKE_ICON[Math.floor(Math.random() * LikeIconAnimationParam.LIKE_ICON.length)]
  width: number = 34
  height: number = 34
  scale: number = 0.3
  translateX: number = 0
  translateY: number = 0
  rotateZ: number = 0
  opacity: number = 1

  start() {
    this.scale = 1.2
    this.translateX = -(40 + Math.floor(Math.random() * 21))
    this.translateY = -160
    this.rotateZ = Math.floor(Math.random() * 61)
    this.opacity = 0.3
    return this
  }
}