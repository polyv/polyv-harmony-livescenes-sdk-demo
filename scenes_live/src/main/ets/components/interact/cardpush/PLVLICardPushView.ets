import {
  PLVCardPushVO,
  PLVCommonConstants,
  PLVLiveSceneSDK,
  PLVLogger,
  PLVNewsPushEvent,
  PLVShowPushCardEvent,
  PLVSocketPushCardEvent,
  PLVTextUtils,
  PLVTimeUtils
} from '@polyvharmony/live-scenes-sdk'
import { PLVCardLookTimeLocalRepository } from './PLVCardLookTimeLocalRepository'

@Component
@Preview
export struct PLVLICardPushView {
  // <editor-fold defaultstate="collapsed" desc="变量">

  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  @State cardPushInfo: PLVCardPushVO = new PLVCardPushVO()
  @State cardImage: Resource | string = ""
  @State cardShow: boolean = false
  @State cardCdShow: boolean = false
  @State cardTipsShow: boolean = false
  @State colors: Array<[ResourceColor, number]> = [["#FF9D4D", 0.0], ["#F65F49", 0.5]]
  @State tipsText: string | Resource = ""
  @State cdText: string = ""

  @State cardWidth: number = 0
  @State cardHeight: number = 0
  @State cdTextHeight: number = 0
  @State tipsWidth: number = 0

  private canSendCardPushEvent = false
  private countDownTaskId?: number
  private showPushCardEvent?: PLVShowPushCardEvent
  // </editor-fold>

  // <editor-fold defaultstate="collapsed" desc="生命周期">

  aboutToAppear(): void {
    this.observer()
  }
  // </editor-fold>

  // <editor-fold defaultstate="collapsed" desc="View内容">
  build() {
    RelativeContainer() {
      Column() {
        if (this.cardShow) {
          Image(this.cardImage)
            .width(34)
            .height(34)
            .onAreaChange((oldValue: Area, newValue: Area) => {
              this.cardWidth = newValue.width as number
              this.cardHeight = newValue.height as number
            })
            .onClick((event) => {
              if (this.showPushCardEvent != undefined && this.canSendCardPushEvent) {
                this.sdk?.interactManager.showCardPush(this.showPushCardEvent)
              }
              if (this.cardCdShow) {
                this.cardTipsShow = true
                setTimeout(() => {
                  this.cardTipsShow = false
                }, 3000)
              }
            })
        }
      }
      .alignRules({
        top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
        right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
      })
      .width(34)
      .height(34)
      .id("cardpush_img")

      if (this.cardCdShow) {
        Row() {
          Text(this.cdText)
            .fontColor("#ADADC0")
            .fontSize(10)
        }
        .onAreaChange((oldValue: Area, newValue: Area) => {
          this.cdTextHeight = newValue.height as number
        })
        .alignRules({
          top: {anchor: "cardpush_img", align: VerticalAlign.Bottom},
          right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
        })
        .id("cardpush_cd_tv")
      }

      if (this.cardTipsShow) {
        Row() {
          Text(this.tipsText)
            .fontSize(13)
            .fontColor("#FFFFFF")
        }
        .borderRadius(4)
        .padding({
          left: 4,
          right: 4,
          top: 3,
          bottom: 3
        })
        .linearGradient({
          direction: GradientDirection.Right,
          colors: this.colors
        })
        .alignRules({
          right: { anchor: "cardpush_img", align: HorizontalAlign.Start },
          top: { anchor: "cardpush_img", align: VerticalAlign.Center }
        })
        .onAreaChange((oldValue: Area, newValue: Area) => {
          this.tipsWidth = newValue.width as number
        })
        .offset({ x: -10, y: -10 })
        .id("cardpush_tips_tv")

        Polygon({ width: 10, height: 10 })
          .points([[0, 0], [0, 8], [4, 4]])
          .fill("#F65F49")
          .alignRules({
            left: { anchor: "cardpush_tips_tv", align: HorizontalAlign.End },
            top: { anchor: "cardpush_tips_tv", align: VerticalAlign.Center }
          })
          .offset({ y: -15, x: -10 })
      }
    }
    .height(this.cardShow ? this.cardHeight + this.cdTextHeight : 0)
    .width(this.cardShow ? this.tipsWidth + this.cardWidth : 0)
  }
  // </editor-fold>

  // <editor-fold defaultstate="collapsed" desc="数据订阅">
  observer() {
    this.sdk?.pushcardManager.eventNotify.on('pushcard_data', (pushEvent: PLVNewsPushEvent) => {
      if (pushEvent.EVENT === PLVSocketPushCardEvent.NEWS_PUSH_START) {
        this.sdk?.pushcardManager.getCardPushInfo(pushEvent.id)
          .then((value) => {
            this.cardPushInfo = value
            this.acceptCardPushVO(value, pushEvent)
          })
      }

      if (pushEvent.EVENT === PLVSocketPushCardEvent.NEWS_PUSH_CANCEL) {
        this.disposeCardPushAllTask()
        this.cardShow = false
        this.cardCdShow = false
        this.cardTipsShow = false
      }
    })
  }
  // </editor-fold>

  // <editor-fold defaultstate="collapsed" desc="内部方法">

  async acceptCardPushVO(cardPushVO: PLVCardPushVO, pushEvent: PLVNewsPushEvent) {
    this.disposeCardPushAllTask()

    const id = pushEvent.id
    const lookTime = pushEvent.lookTime ?? 0
    const alreadyLookTime = await PLVCardLookTimeLocalRepository.getCache(this.sdk?.channelData.loginChannelId!, id!)
    const needLookTime = lookTime - alreadyLookTime
    const isEntrance = pushEvent.isEntrance()
    const isEntranceOrNeedLook = isEntrance || needLookTime > 0
    this.canSendCardPushEvent = needLookTime <= 0

    this.cardShow = isEntranceOrNeedLook
    this.cardCdShow = isEntranceOrNeedLook && needLookTime > 0
    this.cardTipsShow = isEntranceOrNeedLook && lookTime > 0

    if (cardPushVO.isGiftboxType()) {
      this.cardImage = $r('app.media.plvli_interact_giftbox_gain')
      this.colors = [["#F6A125", 0.0], ["#FD8121", 0.0]]
    } else if (cardPushVO.isRedpackType()) {
      this.cardImage = $r('app.media.plvli_interact_redpack_gain')
      this.colors = [["#FF9D4D", 0.0], ["#F65F49", 0.5]]
    } else if (cardPushVO.isCustomType()) {
      const imgUrl = PLVTextUtils.fixPic(cardPushVO.cardImage)
      this.cardImage = imgUrl === "" ? $r('app.media.plvli_interact_redpack_gain') : imgUrl
    }

    this.tipsText = cardPushVO.countdownMsg ?? $r("app.string.plvli_card_push_reward_hint")
    if (needLookTime > 0) {
      setTimeout(() => {
        this.cardTipsShow = false
      }, 3000)
    }

    this.showPushCardEvent = new PLVShowPushCardEvent().setData(pushEvent)

    // 卡片观看计时
    if (needLookTime > 0) {
      this.startCardLookCountdownTask(id!, needLookTime, alreadyLookTime, isEntrance)
    }

  }

  startCardLookCountdownTask(id: string, needLookTime: number, alreadyLookTime: number, isEntrance: boolean) {
    clearInterval(this.countDownTaskId)
    this.countDownTaskId = setInterval(() => {
      needLookTime -= 1000
      PLVCardLookTimeLocalRepository.saveCache(this.sdk?.channelData.loginChannelId!, id, alreadyLookTime += 1000)
      this.cdText = PLVTimeUtils.generateTime(needLookTime, true)
      if (needLookTime <= 0) {
        this.canSendCardPushEvent = true
        // 点击事件
        if (this.showPushCardEvent != undefined) {
          this.sdk?.interactManager.showCardPush(this.showPushCardEvent)
        }

        this.cardCdShow = false
        this.cardTipsShow = false
        if (!isEntrance) {
          this.cardShow = false
        }
        clearInterval(this.countDownTaskId)
      }
    }, 1000)
  }

  disposeCardPushAllTask() {
    clearInterval(this.countDownTaskId)
    this.sdk?.pushcardManager.disposable()
  }

  // </editor-fold>



}
