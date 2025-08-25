import { PLVCommonConstants, PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk';
import {
  extendArray,
  extendNumber,
  lateInit,
  MutableObserver,
  random,
  randomFloat,
  repeat
} from '@polyvharmony/media-player-sdk';
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus';
import { util } from '@kit.ArkTS';
import { AnimatorResult } from '@kit.ArkUI';

@Component
export struct PLVLWLikesParticleLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private readonly likeParticleParams: LikeParticleParam[] = []
  private likesCount: number | undefined = undefined
  private layoutArea: Area | undefined = undefined
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.onLikesCountChanged(this.sdk.chatroomManager.likesCount, false)
    this.layoutDataBus.onClickLike.observe((likesCount) => {
      this.onLikesCountChanged(likesCount, true)
    }).pushTo(this.observers)
    this.sdk.chatroomManager.eventNotify.on('likes_count', (likesCount: number) => {
      this.onLikesCountChanged(likesCount, false)
    })
  }

  private onLikesCountChanged(likesCount: number, fromLocal: boolean) {
    if (this.likesCount === undefined) {
      this.likesCount = likesCount
      return
    }
    const diff = likesCount - this.likesCount
    this.likesCount = likesCount
    if (diff > 0) {
      this.emitParticles(extendNumber(diff).coerceAtMost_ext(5), fromLocal)
    }
  }

  private emitParticles(count: number, fromLocal: boolean) {
    repeat(count, (index) => {
      setTimeout(() => {
        this.emitSingleParticle(fromLocal)
      }, index * 200)
    })
  }

  private emitSingleParticle(fromLocal: boolean) {
    const param = new LikeParticleParam()
    param.fromLocal = fromLocal
    this.likeParticleParams.push(param)
  }

  build() {
    Stack() {
      ForEach(
        this.likeParticleParams,
        (param: LikeParticleParam) => {
          LikeParticle({
            likeParticleParams: this.likeParticleParams,
            param: param,
            parentArea: this.layoutArea
          })
        },
        (param: LikeParticleParam) => param.id
      )
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
    .onAreaChange((oldArea, newArea) => {
      this.layoutArea = newArea
    })
    .hitTestBehavior(HitTestMode.None)
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}

class LikeParticleParam {
  id = util.generateRandomUUID()
  fromLocal: boolean = false
}

const LIKE_ICON: Resource[] = [
  $r("app.media.plvlw_chatroom_btn_like_1"),
  $r("app.media.plvlw_chatroom_btn_like_2"),
  $r("app.media.plvlw_chatroom_btn_like_3"),
  $r("app.media.plvlw_chatroom_btn_like_4"),
  $r("app.media.plvlw_chatroom_btn_like_5"),
  $r("app.media.plvlw_chatroom_btn_like_6"),
  $r("app.media.plvlw_chatroom_btn_like_7"),
  $r("app.media.plvlw_chatroom_btn_like_8"),
  $r("app.media.plvlw_chatroom_btn_like_9"),
  $r("app.media.plvlw_chatroom_btn_like_10"),
]

@Component
struct LikeParticle {
  @Link readonly likeParticleParams: LikeParticleParam[]
  param: LikeParticleParam = lateInit()
  parentArea: Area | undefined = undefined
  private readonly icon = LIKE_ICON[random(0, LIKE_ICON.length)]
  private readonly iconSize = 36 * random(7, 11) / 10
  @State private iconScale: number = 1
  @State private iconAlpha: number = 1
  @State private iconTranslateX: number = 0
  @State private iconTranslateY: number = 0
  private animatorResult: AnimatorResult | undefined = undefined

  aboutToAppear(): void {
    const parentWidth = this.parentArea?.width as number ?? 136
    const parentHeight = this.parentArea?.width as number ?? 169
    const pointStart = new Point(parentWidth - this.iconSize, parentHeight - this.iconSize)
    const pointC1 = new Point(
      randomFloat(0, 1) * parentWidth,
      randomFloat(0.5, 1) * parentHeight
    )
    const pointC2 = new Point(
      randomFloat(0, 1) * parentWidth,
      randomFloat(0, 0.5) * parentHeight
    )
    const pointEnd = new Point(randomFloat(0, 1) * (parentWidth - this.iconSize) / 2, 0)

    this.animatorResult = this.getUIContext().createAnimator({
      duration: 2000,
      delay: 0,
      iterations: 1,
      easing: 'linear',
      begin: 0,
      end: 1,
      fill: "none",
      direction: "normal"
    })
    this.animatorResult.onFrame = (t: number) => {
      const x = pointStart.x * (1 - t) * (1 - t) * (1 - t)
        + 3 * pointC1.x * t * (1 - t) * (1 - t)
        + 3 * pointC2.x * t * t * (1 - t)
        + pointEnd.x * t * t * t;
      const y = pointStart.y * (1 - t) * (1 - t) * (1 - t)
        + 3 * pointC1.y * t * (1 - t) * (1 - t)
        + 3 * pointC2.y * t * t * (1 - t)
        + pointEnd.y * t * t * t;
      this.iconTranslateX = x - parentWidth / 2
      this.iconTranslateY = y - parentHeight / 2
      this.iconAlpha = this.param.fromLocal ? extendNumber(1.5 - t).coerceAtMost_ext(1) : 0.3
      this.iconScale = extendNumber(0.5 + t).coerceAtMost_ext(1)
    }
    this.animatorResult.onFinish = () => {
      this.removeSelfParam()
    }
    this.animatorResult.onCancel = () => {
      this.removeSelfParam()
    }
    this.animatorResult?.play()
  }

  build() {
    Image(this.icon)
      .width(this.iconSize)
      .height(this.iconSize)
      .opacity(this.iconAlpha)
      .translate({
        x: this.iconTranslateX,
        y: this.iconTranslateY
      })
      .scale({
        x: this.iconScale,
        y: this.iconScale
      })
  }

  private removeSelfParam() {
    extendArray(this.likeParticleParams).remove_ext(this.param)
  }

  aboutToDisappear(): void {
    this.animatorResult?.cancel()
  }
}

class Point {
  x: number
  y: number

  constructor(x: number, y: number) {
    this.x = x
    this.y = y
  }
}