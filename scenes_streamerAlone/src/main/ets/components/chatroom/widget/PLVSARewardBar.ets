import {
  PLVCommonConstants,
  PLVJSONUtils,
  PLVLiveSceneSDK,
  PLVRewardEvent,
  PLVSocketOnEvent
} from '@polyvharmony/live-scenes-sdk';
import { isTextEmpty, lateInit, PLVMediaPlayerAppContext } from '@polyvharmony/media-player-sdk';

const REWARD_BAR_WIDTH = 270

@Component
export struct PLVSARewardBar {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  private showRewardRunning: boolean = false
  @State private translationX: number = -REWARD_BAR_WIDTH
  @State private nickName: string = ""
  @State private giftAction: Resource = $r('app.string.plvsa_reward_gift_give')
  @State private giftName: string = ""
  @State private giftImage: string | Resource = ""
  @State private giftCount: number = 1
  private readonly rewardQueue: PLVRewardEvent[] = []

  aboutToAppear(): void {
    this.sdk?.chatroomManager.onData(PLVSocketOnEvent.MESSAGE, (data: string, event: string) => {
      if (event === PLVRewardEvent.EVENT) {
        this.onRewardEvent(data)
      }
    }, this)
  }

  build() {
    RelativeContainer() {
      Image($r('app.media.plvsa_chat_reward_bg'))
        .id('plvsa_chat_reward_bg')
        .width('100%')
        .height(40)
        .objectFit(ImageFit.Fill)
        .alignRules({
          bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
        })

      Column() {
        Text(this.nickName)
          .constraintSize({
            maxWidth: 124
          })
          .maxLines(1)
          .textOverflow({
            overflow: TextOverflow.Ellipsis
          })
          .ellipsisMode(EllipsisMode.END)
          .fontColor('#FCF2A6')
          .fontSize(14)

        Row() {
          Text(this.giftAction)
            .fontColor('#FFFFFF')
            .fontSize(10)
          Text(this.giftName)
            .fontColor('#FFFFFF')
            .fontSize(10)
            .margin({
              left: 2
            })
        }
      }
      .id('plvsa_reward_bar_gift_content')
      .alignItems(HorizontalAlign.Start)
      .alignRules({
        left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
        center: { anchor: 'plvsa_chat_reward_bg', align: VerticalAlign.Center }
      })
      .margin({
        left: 16
      })

      Image(this.giftImage)
        .id('plvsa_reward_bar_gift_image')
        .width(56)
        .objectFit(ImageFit.Cover)
        .alignRules({
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
          bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
        })
        .margin({
          left: 150
        })

      if (this.giftCount > 1) {
        Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Baseline }) {
          Text("x")
            .fontColor('#F47E04')
            .fontSize(20)
            .fontStyle(FontStyle.Italic)
          Text(this.giftCount.toString())
            .fontColor('#F47E04')
            .fontSize(28)
            .fontStyle(FontStyle.Italic)
            .margin({
              left: 2
            })
        }
        .id('plvsa_reward_bar_count_times')
        .alignRules({
          left: { anchor: 'plvsa_reward_bar_gift_image', align: HorizontalAlign.End },
          bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
        })
        .margin({
          left: 4
        })
      }
    }
    .width(REWARD_BAR_WIDTH)
    .translate({
      x: this.translationX
    })
  }

  private onRewardEvent(data: string) {
    const rewardEvent = PLVJSONUtils.toFillData(PLVRewardEvent, data);
    if (rewardEvent === undefined) {
      return
    }
    this.rewardQueue.push(rewardEvent)
    if (this.rewardQueue.length > 10) {
      this.rewardQueue.shift()
    }
    this.showFirstRewardEvent()
  }

  private async showFirstRewardEvent() {
    if (this.showRewardRunning) {
      return
    }
    this.showRewardRunning = true
    const rewardEvent = this.rewardQueue.shift()
    if (rewardEvent === undefined) {
      this.showRewardRunning = false
      return
    }
    const isGift = !isTextEmpty(rewardEvent.content?.getGimg())
    this.nickName = rewardEvent.content?.unick ?? ""
    if (isGift) {
      this.giftAction = $r('app.string.plvsa_reward_gift_give')
      this.giftName = rewardEvent.content?.rewardContent ?? ""
      this.giftImage = rewardEvent.content?.getGimg() ?? ""
    } else {
      this.giftAction = $r('app.string.plvsa_reward_money_give')
      this.giftName = `${rewardEvent.content?.rewardContent}${PLVMediaPlayerAppContext.getString($r('app.string.plvsa_reward_money_give_unit_cny'))}`
      this.giftImage = $r('app.media.plvsa_chat_reward_money_img')
    }
    this.giftCount = rewardEvent.content?.goodNum ?? 1

    this.getUIContext().animateTo(
      { curve: Curve.Smooth, duration: 400 },
      () => {
        this.translationX = 0
      }
    )
    setTimeout(() => {
      this.hideRewardOrShowNext()
    }, 400 + 1200)
  }

  private hideRewardOrShowNext() {
    const hasNextReward = this.rewardQueue.length > 0
    if (hasNextReward) {
      this.showRewardRunning = false
      this.translationX = -REWARD_BAR_WIDTH
      this.showFirstRewardEvent()
    } else {
      this.showRewardRunning = false
      this.getUIContext().animateTo(
        { curve: Curve.Smooth, duration: 400 },
        () => {
          this.translationX = -REWARD_BAR_WIDTH
        }
      )
    }
  }

  aboutToDisappear(): void {
  }
}
