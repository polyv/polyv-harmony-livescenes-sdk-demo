import { PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk'
import { lateInit, MutableObserver } from '@polyvharmony/media-player-sdk'
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus'
import {
  InteractPopupView,
  InteractSideBarAction,
  InteractSideBarActionManager,
  InteractSideBarView
} from './interact-side-bar-action-common'

@Component
export struct PLVLWInteractSideBarQuestionnaireAction {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('sideBarActionManager') sideBarActionManager: InteractSideBarActionManager
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.layoutDataBus.preload.interactData.observe(data => {
      const questionnaireEvent = data?.callAppEvent?.getDataArray()?.find(it => it.isShowQuestionnaireEvent())
      if (questionnaireEvent) {
        this.sideBarActionManager.onActionAvailable(new InteractSideBarAction('Questionnaire', questionnaireEvent))
      } else {
        this.sideBarActionManager.onActionCancel('Questionnaire')
      }
    })
      .pushTo(this.observers)
  }

  build() {

  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}

@Component
export struct PLVLWInteractSideBarQuestionnaireActionSideBarView {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('sideBarActionManager') sideBarActionManager: InteractSideBarActionManager

  build() {
    InteractSideBarView({
      icon: $r('app.media.plvlw_interact_side_bar_questionnaire_icon'),
      title: $r('app.string.plvlw_interact_questionnaire_icon_text')
    })
      .onClick(() => {
        this.sdk.interactManager.showQuestionnaire()
      })
  }

}

@Component
export struct PLVLWInteractSideBarQuestionnaireActionPopupView {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('sideBarActionManager') sideBarActionManager: InteractSideBarActionManager

  build() {
    InteractPopupView({
      icon: $r('app.media.plvlw_interact_side_bar_questionnaire_icon'),
      iconText: $r('app.string.plvlw_interact_questionnaire_icon_text'),
      title: $r('app.string.plvlw_interact_questionnaire_title')
    })
      .onClick(() => {
        this.sideBarActionManager.closeMoreActionDialog?.()
        this.sdk.interactManager.showQuestionnaire()
      })
  }
}