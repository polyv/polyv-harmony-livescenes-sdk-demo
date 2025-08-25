import {
  PLVCardLookTimeLocalRepository,
  PLVCardPushVO,
  PLVLiveSceneSDK,
  PLVNewsPushEvent,
  PLVShowPushCardEvent,
  PLVTimeUtils
} from '@polyvharmony/live-scenes-sdk'
import { lateInit, MutableObserver, mutableStateOf } from '@polyvharmony/media-player-sdk'
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus'
import {
  InteractPopupView,
  InteractSideBarAction,
  InteractSideBarActionManager,
  InteractSideBarView
} from './interact-side-bar-action-common'

@Component
export struct PLVLWInteractSideBarCardPushAction {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @Consume('sideBarActionManager') sideBarActionManager: InteractSideBarActionManager
  private payload: CardPushPayload | undefined = undefined
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.layoutDataBus.preload.cardPushEvent.observe(cardPushEvent => {
      if (cardPushEvent) {
        this.onCardPushStart(cardPushEvent)
      } else {
        this.onCardPushCancel()
      }
    })
      .pushTo(this.observers)
  }

  private async onCardPushStart(event: PLVNewsPushEvent) {
    this.onCardPushCancel()

    const cardPushInfo = await this.sdk.pushcardManager.getCardPushInfo(event.id)
    this.payload = new CardPushPayload()
    this.payload.startEvent = event
    this.payload.cardPushInfo = cardPushInfo
    await this.setupLookTimeInterval(this.payload, event, cardPushInfo)
    const action = new InteractSideBarAction('CardPush', this.payload)
    this.sideBarActionManager.onActionAvailable(action)
  }

  private async setupLookTimeInterval(payload: CardPushPayload, event: PLVNewsPushEvent, cardPushInfo: PLVCardPushVO) {
    const id = event.id!
    const needLookTime = event.lookTime ?? 0
    const keepEntrance = event.isEntrance()
    let lookTime = await PLVCardLookTimeLocalRepository.getCache(this.sdk.channelData.loginChannelId!, id)
    payload.alreadyLookTime.value = lookTime

    payload.lookTimeIntervalId = setInterval(() => {
      lookTime += 1000
      payload.alreadyLookTime.value = lookTime
      PLVCardLookTimeLocalRepository.saveCache(this.sdk.channelData.loginChannelId!, id, lookTime)
      const restLookTime = needLookTime - lookTime
      if (restLookTime <= 0) {
        clearInterval(payload.lookTimeIntervalId)
        this.sdk.interactManager.showCardPush(new PLVShowPushCardEvent().setData(event))
        if (!keepEntrance) {
          this.onCardPushCancel()
        }
      }
    }, 1000)
  }

  private onCardPushCancel() {
    this.sideBarActionManager.onActionCancel('CardPush')
    clearInterval(this.payload?.lookTimeIntervalId)
    this.payload?.alreadyLookTime?.disposeAll()
    this.payload = undefined
  }

  build() {

  }

  aboutToDisappear(): void {
    clearInterval(this.payload?.lookTimeIntervalId)
    this.payload?.alreadyLookTime?.disposeAll()
    MutableObserver.disposeAll(this.observers)
  }
}

class CardPushPayload {
  startEvent?: PLVNewsPushEvent
  cardPushInfo?: PLVCardPushVO
  alreadyLookTime = mutableStateOf(0)
  lookTimeIntervalId: number | undefined = undefined
}

@Component
export struct PLVLWInteractSideBarCardPushActionSideBarView {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('sideBarActionManager') sideBarActionManager: InteractSideBarActionManager
  @State private image: ResourceStr = ''
  @State private title: ResourceStr = ''
  private startEvent: PLVNewsPushEvent | undefined = undefined
  private cardPushInfo: PLVCardPushVO | undefined = undefined
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    const action = this.sideBarActionManager.getActionWithType('CardPush')
    const payload = action?.payload as CardPushPayload
    if (!payload) {
      return
    }
    this.startEvent = payload.startEvent
    this.cardPushInfo = payload.cardPushInfo

    if (this.cardPushInfo?.isCustomType()) {
      this.image = this.cardPushInfo!.enterImage ?? ''
    } else {
      this.image = $r('app.media.plvlw_interact_side_bar_card_push_icon')
    }

    const needLookTime = this.startEvent?.lookTime ?? 0
    payload.alreadyLookTime.observe(lookTime => {
      const restLookTime = needLookTime - lookTime
      if (restLookTime <= 0) {
        this.title = $r('app.string.plvlw_interact_card_push_receive')
      } else {
        this.title = PLVTimeUtils.generateTime(restLookTime, false)
      }
    }).pushTo(this.observers)
  }

  build() {
    InteractSideBarView({
      icon: this.image,
      title: this.title
    })
      .onClick(() => {
        this.onClickShowCardPush()
      })
  }

  private onClickShowCardPush() {
    this.sdk.interactManager.showCardPush(new PLVShowPushCardEvent().setData(this.startEvent))
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}

@Component
export struct PLVLWInteractSideBarCardPushActionPopupView {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('sideBarActionManager') sideBarActionManager: InteractSideBarActionManager
  @State private image: ResourceStr = ''
  @State private title: ResourceStr = ''
  private startEvent: PLVNewsPushEvent | undefined = undefined
  private cardPushInfo: PLVCardPushVO | undefined = undefined
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    const action = this.sideBarActionManager.getActionWithType('CardPush')
    const payload = action?.payload as CardPushPayload
    if (!payload) {
      return
    }
    this.startEvent = payload.startEvent
    this.cardPushInfo = payload.cardPushInfo

    if (this.cardPushInfo?.isCustomType()) {
      this.image = this.cardPushInfo!.enterImage ?? ''
    } else {
      this.image = $r('app.media.plvlw_interact_side_bar_card_push_icon')
    }

    const needLookTime = this.startEvent?.lookTime ?? 0
    payload.alreadyLookTime.observe(lookTime => {
      const restLookTime = needLookTime - lookTime
      if (restLookTime <= 0) {
        this.title = $r('app.string.plvlw_interact_card_push_receive')
      } else {
        this.title = PLVTimeUtils.generateTime(restLookTime, false)
      }
    }).pushTo(this.observers)
  }

  build() {
    InteractPopupView({
      icon: this.image,
      iconText: this.title,
      title: $r('app.string.plvlw_interact_card_push_title')
    })
      .onClick(() => {
        this.onClickShowCardPush()
      })
  }

  private onClickShowCardPush() {
    this.sideBarActionManager.closeMoreActionDialog?.()
    this.sdk.interactManager.showCardPush(new PLVShowPushCardEvent().setData(this.startEvent))
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}