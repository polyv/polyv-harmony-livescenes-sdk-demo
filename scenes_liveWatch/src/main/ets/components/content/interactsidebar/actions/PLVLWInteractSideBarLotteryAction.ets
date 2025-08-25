import { FunctionBean, PLVLiveSceneSDK, PLVTimeUtils } from '@polyvharmony/live-scenes-sdk'
import { lateInit, MutableObserver, mutableStateOf, seconds } from '@polyvharmony/media-player-sdk'
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus'
import {
  InteractPopupView,
  InteractSideBarAction,
  InteractSideBarActionManager,
  InteractSideBarView
} from './interact-side-bar-action-common'

const LOTTERY_STATUS_DELAY_TIME = "delayTime"
const LOTTERY_STATUS_RUNNING = "running"
const LOTTERY_STATUS_OVER = "over"

@Component
export struct PLVLWInteractSideBarLotteryAction {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('sideBarActionManager') sideBarActionManager: InteractSideBarActionManager
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  private readonly lotteryPayload = new LotteryPayload()
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.layoutDataBus.preload.interactStatusPendant.observe(data => {
      const lotteryEvent = data?.value?.dataArray?.find(it => it.event === 'CLICK_LOTTERY_PENDANT')
      if (lotteryEvent) {
        this.lotteryPayload.lotteryState.value = lotteryEvent
      }
      if (!lotteryEvent?.isShow || ![LOTTERY_STATUS_DELAY_TIME, LOTTERY_STATUS_RUNNING, LOTTERY_STATUS_OVER].some(it => it === lotteryEvent.status)) {
        this.sideBarActionManager.onActionCancel('Lottery')
      } else {
        this.sideBarActionManager.onActionAvailable(new InteractSideBarAction('Lottery', this.lotteryPayload))
      }
    })
      .pushTo(this.observers)
  }

  build() {

  }

  aboutToDisappear(): void {
    this.lotteryPayload.lotteryState.disposeAll()
    MutableObserver.disposeAll(this.observers)
  }
}

class LotteryPayload {
  readonly lotteryState = mutableStateOf<FunctionBean>()
}

@Component
export struct PLVLWInteractSideBarLotteryActionSideBarView {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('sideBarActionManager') sideBarActionManager: InteractSideBarActionManager
  @State private showText: ResourceStr = ''
  private lotteryEvent: FunctionBean | undefined = undefined
  private countDownIntervalId: number | undefined = undefined
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    const payload = this.sideBarActionManager.getActionWithType('Lottery')?.payload as LotteryPayload | undefined
    if (!payload) {
      return
    }
    payload.lotteryState.observe(lotteryEvent => {
      this.lotteryEvent = lotteryEvent
      switch (lotteryEvent.status) {
        case LOTTERY_STATUS_DELAY_TIME: {
          this.onLotteryCountDown(lotteryEvent)
          break
        }
        case LOTTERY_STATUS_RUNNING: {
          this.onLotteryRunning()
          break
        }
        case LOTTERY_STATUS_OVER: {
          this.onLotteryOver()
          break
        }
      }
    }).pushTo(this.observers)
  }

  private onLotteryCountDown(lotteryEvent: FunctionBean) {
    const toRunningTimestamp = Date.now() + seconds(lotteryEvent.delayTime ?? 0).toMillis()
    clearInterval(this.countDownIntervalId)
    const updateShowText = () => {
      if (Date.now() >= toRunningTimestamp) {
        this.onLotteryRunning()
        return
      }
      const restTime = toRunningTimestamp - Date.now()
      this.showText = PLVTimeUtils.generateTime(restTime, false)
    }
    updateShowText()
    this.countDownIntervalId = setInterval(() => {
      updateShowText()
    }, 1000)
  }

  private onLotteryRunning() {
    clearInterval(this.countDownIntervalId)
    this.showText = $r('app.string.plvlw_lottery_running')
  }

  private onLotteryOver() {
    clearInterval(this.countDownIntervalId)
    this.showText = $r('app.string.plvlw_lottery_over')
  }

  build() {
    InteractSideBarView({
      icon: $r('app.media.plvlw_interact_side_bar_lottery_icon'),
      title: this.showText
    }).onClick(() => {
      if ([LOTTERY_STATUS_RUNNING, LOTTERY_STATUS_OVER].includes(this.lotteryEvent?.status ?? '')) {
        this.sdk.interactManager.showLottery()
      }
    })
  }

  aboutToDisappear(): void {
    clearInterval(this.countDownIntervalId)
    MutableObserver.disposeAll(this.observers)
  }
}

@Component
export struct PLVLWInteractSideBarLotteryActionPopupView {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('sideBarActionManager') sideBarActionManager: InteractSideBarActionManager
  @State private showText: ResourceStr = ''
  private lotteryEvent: FunctionBean | undefined = undefined
  private countDownIntervalId: number | undefined = undefined
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    const payload = this.sideBarActionManager.getActionWithType('Lottery')?.payload as LotteryPayload | undefined
    if (!payload) {
      return
    }
    payload.lotteryState.observe(lotteryEvent => {
      this.lotteryEvent = lotteryEvent
      switch (lotteryEvent.status) {
        case LOTTERY_STATUS_DELAY_TIME: {
          this.onLotteryCountDown(lotteryEvent)
          break
        }
        case LOTTERY_STATUS_RUNNING: {
          this.onLotteryRunning()
          break
        }
        case LOTTERY_STATUS_OVER: {
          this.onLotteryOver()
          break
        }
      }
    }).pushTo(this.observers)
  }

  private onLotteryCountDown(lotteryEvent: FunctionBean) {
    const toRunningTimestamp = Date.now() + seconds(lotteryEvent.delayTime ?? 0).toMillis()
    clearInterval(this.countDownIntervalId)
    const updateShowText = () => {
      if (Date.now() >= toRunningTimestamp) {
        this.onLotteryRunning()
        return
      }
      const restTime = toRunningTimestamp - Date.now()
      this.showText = PLVTimeUtils.generateTime(restTime, false)
    }
    updateShowText()
    this.countDownIntervalId = setInterval(() => {
      updateShowText()
    }, 1000)
  }

  private onLotteryRunning() {
    clearInterval(this.countDownIntervalId)
    this.showText = $r('app.string.plvlw_lottery_running')
  }

  private onLotteryOver() {
    clearInterval(this.countDownIntervalId)
    this.showText = $r('app.string.plvlw_lottery_over')
  }

  build() {
    InteractPopupView({
      icon: $r('app.media.plvlw_interact_side_bar_lottery_icon'),
      iconText: this.showText,
      title: $r('app.string.plvlw_interact_lottery_title')
    }).onClick(() => {
      if ([LOTTERY_STATUS_RUNNING, LOTTERY_STATUS_OVER].includes(this.lotteryEvent?.status ?? '')) {
        this.sideBarActionManager.closeMoreActionDialog?.()
        this.sdk.interactManager.showLottery()
      }
    })
  }

  aboutToDisappear(): void {
    clearInterval(this.countDownIntervalId)
    MutableObserver.disposeAll(this.observers)
  }
}