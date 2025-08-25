import { PLVDelayRedpackVO, PLVLiveSceneSDK, PLVTimeUtils } from '@polyvharmony/live-scenes-sdk'
import { lateInit } from '@polyvharmony/media-player-sdk'
import {
  InteractPopupView,
  InteractSideBarAction,
  InteractSideBarActionManager,
  InteractSideBarView
} from './interact-side-bar-action-common'

@Component
export struct PLVLWInteractSideBarRedpackAction {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('sideBarActionManager') sideBarActionManager: InteractSideBarActionManager
  private delayRedPaperEvent: PLVDelayRedpackVO | undefined = undefined
  private redPaperTimeoutId: number | undefined = undefined

  aboutToAppear(): void {
    this.sdk.redpackManager.updateDelayRedpackStatus(this.sdk.channelData.loginChannelId)
    this.sdk.redpackManager.eventDataNotify.on("redpack_data", (data: PLVDelayRedpackVO) => {
      this.delayRedPaperEvent = data
      if (this.delayRedPaperEvent?.redpackSendTime && this.delayRedPaperEvent.redpackSendTime > Date.now()) {
        this.onRedpackCountDown()
        this.sideBarActionManager.onActionAvailable(new InteractSideBarAction('Redpack', this.delayRedPaperEvent))
      } else {
        this.onRedpackHide()
      }
    })
  }

  private onRedpackCountDown() {
    clearTimeout(this.redPaperTimeoutId)
    if (this.delayRedPaperEvent?.redpackSendTime === undefined) {
      return
    }
    const delayTime = this.delayRedPaperEvent?.redpackSendTime - Date.now()
    this.redPaperTimeoutId = setTimeout(() => {
      this.onRedpackHide()
    }, delayTime)
  }

  private onRedpackHide() {
    clearTimeout(this.redPaperTimeoutId)
    this.sideBarActionManager.onActionCancel('Redpack')
  }

  build() {

  }

  aboutToDisappear(): void {
    clearTimeout(this.redPaperTimeoutId)
  }
}

@Component
export struct PLVLWInteractSideBarRedpackActionSideBarView {
  @Consume('sideBarActionManager') sideBarActionManager: InteractSideBarActionManager
  @State private countDownTime: number = 0
  private delayRedPaperEvent: PLVDelayRedpackVO | undefined = undefined
  private countDownIntervalId: number | undefined = undefined

  aboutToAppear(): void {
    const action = this.sideBarActionManager.getActionWithType('Redpack')
    this.delayRedPaperEvent = action?.payload as PLVDelayRedpackVO | undefined
    const sendTime = this.delayRedPaperEvent?.redpackSendTime
    if (sendTime) {
      this.countDownTime = sendTime - Date.now()
      this.countDownIntervalId = setInterval(() => {
        this.countDownTime = sendTime - Date.now()
      }, 1000)
    }
  }

  build() {
    InteractSideBarView({
      icon: $r('app.media.plvlw_interact_side_bar_password_redpack_icon'),
      title: this.countDownTime > 0 ? PLVTimeUtils.generateTime(this.countDownTime, false) : $r('app.string.plv_live_scenes_sdk_red_paper_name')
    })
  }

  aboutToDisappear(): void {
    clearInterval(this.countDownIntervalId)
  }
}

@Component
export struct PLVLWInteractSideBarRedpackActionPopupView {
  @Consume('sideBarActionManager') sideBarActionManager: InteractSideBarActionManager
  @State private countDownTime: number = 0
  private delayRedPaperEvent: PLVDelayRedpackVO | undefined = undefined
  private countDownIntervalId: number | undefined = undefined

  aboutToAppear(): void {
    const action = this.sideBarActionManager.getActionWithType('Redpack')
    this.delayRedPaperEvent = action?.payload as PLVDelayRedpackVO | undefined
    const sendTime = this.delayRedPaperEvent?.redpackSendTime
    if (sendTime) {
      this.countDownTime = sendTime - Date.now()
      this.countDownIntervalId = setInterval(() => {
        this.countDownTime = sendTime - Date.now()
      }, 1000)
    }
  }

  build() {
    InteractPopupView({
      icon: $r('app.media.plvlw_interact_side_bar_password_redpack_icon'),
      iconText: this.countDownTime > 0 ? PLVTimeUtils.generateTime(this.countDownTime, false) : $r('app.string.plv_live_scenes_sdk_red_paper_name'),
      title: $r('app.string.plv_live_scenes_sdk_red_paper_name')
    })
  }

  aboutToDisappear(): void {
    clearInterval(this.countDownIntervalId)
  }
}