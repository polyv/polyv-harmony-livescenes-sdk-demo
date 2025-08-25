import {
  PLVCommonConstants,
  PLVJSONUtils,
  PLVLiveSceneSDK,
  PLVRewardEvent,
  PLVSocketOnEvent
} from '@polyvharmony/live-scenes-sdk';
import {
  delay,
  extendArray,
  lateInit,
  MutableObserver,
  PLVMediaPlayerAppContext,
  Promises,
  randomInt,
  watchStates
} from '@polyvharmony/media-player-sdk';
import { CircleShape, display } from '@kit.ArkUI';
import { PLVLWLayoutDataBus } from '../../../common/PLVLWLayoutDataBus';

const ITEM_EXPAND_DURATION = 300
const ITEM_MOVE_IN_DURATION = 500
const ITEM_SHOW_DURATION = 3000
const ITEM_HIDE_DURATION = 300
const ITEM_SHRINK_DURATION = 300
const MAX_CACHE_REWARD = 100
const REWARD_ITEM_BACKGROUND_GRADIENTS: [ResourceColor, number][][] = [
  [['#80000000', 0], ['#1A000000', 1]],
  [['#995B46FF', 0], ['#1A5B46FF', 1]],
  [['#B357ADFF', 0], ['#1A57ADFF', 1]],
  [['#992DD0C0', 0], ['#1A2DD0C0', 1]],
  [['#9928DE7A', 0], ['#1A28DE7A', 1]],
  [['#B3FFC145', 0], ['#1AFFC145', 1]],
  [['#99FF67C2', 0], ['#1AFF67C2', 1]],
  [['#99FF4646', 0], ['#1AFF4646', 1]],
]
const AVATAR_DEFAULT = "https://liveimages.videocc.net/defaultImg/avatar/viewer.png"

@Component
export struct PLVLWRewardMessageLayout {
  maxShowRewards: number = 2
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private readonly showingRewardEvents: PLVRewardEvent[] = []
  @State private isPortrait: boolean = true
  @State private isPlayerFullscreen: boolean = true
  private readonly rewardEventQueue: PLVRewardEvent[] = []
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.chatroomManager.onData(PLVSocketOnEvent.MESSAGE, this.onSocketMessage, this)
    watchStates(() => {
      this.isPortrait = this.layoutDataBus.isPortrait.value ?? true
      this.isPlayerFullscreen = this.layoutDataBus.playerFullscreen.value ?? false
    }).pushTo(this.observers)
  }

  build() {
    Column() {
      ForEach(
        this.showingRewardEvents,
        (event: PLVRewardEvent) => {
          RewardMessageItem({
            rewardEvent: event,
            onFinish: () => {
              extendArray(this.showingRewardEvents).remove_ext(event)
              this.pickRewardEventToShow()
            }
          })
        },
        (event: PLVRewardEvent) => event.getUniqueId()
      )
    }
    .width(this.isPortrait ? PLVCommonConstants.FULL_PERCENT : 'auto')
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.isPortrait && !this.isPlayerFullscreen ? $r('app.color.plvlw_theme_bg_blue_merge_dark_70') : Color.Transparent)
    .backdropBlur(this.isPortrait && this.isPlayerFullscreen ? 40 : 0)
  }

  private readonly onSocketMessage = (data: string, event: string) => {
    switch (event) {
      case PLVRewardEvent.EVENT: {
        const rewardEvent = PLVJSONUtils.toFillData(PLVRewardEvent, data)
        if (rewardEvent) {
          this.onRewardEvent(rewardEvent)
        }
        break;
      }
    }
  }

  private onRewardEvent(event: PLVRewardEvent) {
    this.rewardEventQueue.push(event)
    if (this.rewardEventQueue.length > MAX_CACHE_REWARD) {
      this.rewardEventQueue.shift()
    }
    this.pickRewardEventToShow()
  }

  private pickRewardEventToShow() {
    if (this.showingRewardEvents.length >= this.maxShowRewards) {
      return
    }
    const event = this.rewardEventQueue.shift()
    if (!event) {
      return
    }
    this.showingRewardEvents.push(event)
  }

  aboutToDisappear(): void {
    this.sdk.chatroomManager.offData(PLVSocketOnEvent.MESSAGE, this.onSocketMessage, this)
    MutableObserver.disposeAll(this.observers)
  }
}

@Component
struct RewardMessageItem {
  rewardEvent: PLVRewardEvent = lateInit()
  onFinish: () => void = lateInit()
  @State private itemHeight: number = 0
  @State private itemTranslateX: number = -px2vp(display.getDefaultDisplaySync().width)
  @State private itemAlpha: number = 1
  @State private avatarUrl: string = AVATAR_DEFAULT
  @State private nick: string = ''
  @State private giftText: string = ''
  @State private giftImage: string = ''
  @State private giftCount: number = 1

  aboutToAppear(): void {
    this.avatarUrl = this.rewardEvent.content?.getUimg() ?? AVATAR_DEFAULT
    this.nick = this.rewardEvent.content?.unick ?? ''
    this.giftText = PLVMediaPlayerAppContext.getString($r('app.string.plvlw_reward_give'), this.rewardEvent.content?.rewardContent ?? '')
    this.giftImage = this.rewardEvent.content?.getGimg() ?? ''
    this.giftCount = this.rewardEvent.content?.goodNum ?? 1

    this.runAnim()
  }

  build() {
    Row() {
      RelativeContainer() {
        Image(this.avatarUrl)
          .id('reward_item_avatar')
          .width(28)
          .height(28)
          .alignRules({
            left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
            center: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Center }
          })
          .margin({
            left: 4
          })
          .clipShape(new CircleShape({ width: 28, height: 28 }))

        Text(this.nick)
          .id('reward_item_nick')
          .fontSize(12)
          .fontColor($r('app.color.plvlw_reward_message_nick_text'))
          .alignRules({
            top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
            left: { anchor: 'reward_item_avatar', align: HorizontalAlign.End },
            right: { anchor: 'reward_item_gift_image', align: HorizontalAlign.Start }
          })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .ellipsisMode(EllipsisMode.END)
          .margin({
            left: 8,
            right: 4,
            top: 2
          })

        Text(this.giftText)
          .id('reward_item_gift_content')
          .fontSize(10)
          .fontColor($r('app.color.plvlw_reward_message_gift_text'))
          .alignRules({
            bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom },
            left: { anchor: 'reward_item_avatar', align: HorizontalAlign.End },
            right: { anchor: 'reward_item_gift_image', align: HorizontalAlign.Start }
          })
          .margin({
            left: 8,
            right: 4,
            bottom: 3
          })

        Image(this.giftImage)
          .id('reward_item_gift_image')
          .width(36)
          .height(36)
          .alignRules({
            right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End },
            center: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Center }
          })
          .margin({
            right: 4
          })
      }
      .width(146)
      .height(36)
      .borderRadius(18)
      .linearGradient({
        angle: 90,
        colors: REWARD_ITEM_BACKGROUND_GRADIENTS[randomInt(0, REWARD_ITEM_BACKGROUND_GRADIENTS.length)]
      })

      if (this.giftCount > 1) {
        Text('x')
          .fontSize(20)
          .fontColor('#FFFFFF')
          .margin({
            left: 8
          })
        Text(this.giftCount.toString())
          .fontSize(24)
          .fontColor('#FFFFFF')
          .margin({
            left: 2
          })
        Blank()
          .width(8)
      }
    }
    .height(this.itemHeight)
    .clip(false)
    .translate({
      x: this.itemTranslateX
    })
    .opacity(this.itemAlpha)
  }

  private async runAnim() {
    await Promise.all([this.expand(), this.moveIn()])
    await delay(ITEM_SHOW_DURATION)
    await Promise.all([this.hide(), this.shrink()])
    this.onFinish()
  }

  private expand() {
    const promise = Promises.withResolvers<void>()
    this.getUIContext().animateTo({
      duration: ITEM_EXPAND_DURATION,
      onFinish: () => {
        promise.resolve()
      }
    }, () => {
      this.itemHeight = 40
    })
    return promise.promise
  }

  private moveIn() {
    const promise = Promises.withResolvers<void>()
    this.getUIContext().animateTo({
      duration: ITEM_MOVE_IN_DURATION,
      onFinish: () => {
        promise.resolve()
      }
    }, () => {
      this.itemTranslateX = 0
    })
    return promise.promise
  }

  private hide() {
    const promise = Promises.withResolvers<void>()
    this.getUIContext().animateTo({
      duration: ITEM_HIDE_DURATION,
      onFinish: () => {
        promise.resolve()
      }
    }, () => {
      this.itemAlpha = 0
    })
    return promise.promise
  }

  private shrink() {
    const promise = Promises.withResolvers<void>()
    this.getUIContext().animateTo({
      duration: ITEM_SHRINK_DURATION,
      onFinish: () => {
        promise.resolve()
      }
    }, () => {
      this.itemHeight = 0
    })
    return promise.promise
  }
}