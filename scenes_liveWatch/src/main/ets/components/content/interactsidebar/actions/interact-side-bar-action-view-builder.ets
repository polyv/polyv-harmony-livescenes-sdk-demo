import { PLVCommonConstants } from '@polyvharmony/live-scenes-sdk'
import { lateInit } from '@polyvharmony/media-player-sdk'
import { InteractSideBarActionType } from './interact-side-bar-action-common'
import {
  PLVLWInteractSideBarCardPushActionPopupView,
  PLVLWInteractSideBarCardPushActionSideBarView
} from './PLVLWInteractSideBarCardPushAction'
import {
  PLVLWInteractSideBarLotteryActionPopupView,
  PLVLWInteractSideBarLotteryActionSideBarView
} from './PLVLWInteractSideBarLotteryAction'
import {
  PLVLWInteractSideBarQuestionnaireActionPopupView,
  PLVLWInteractSideBarQuestionnaireActionSideBarView
} from './PLVLWInteractSideBarQuestionnaireAction'
import {
  PLVLWInteractSideBarRedpackActionPopupView,
  PLVLWInteractSideBarRedpackActionSideBarView
} from './PLVLWInteractSideBarRedpackAction'

@Component
export struct PLVLWInteractSideBarActionSideBarViewBuilder {
  actionType: InteractSideBarActionType = lateInit()

  build() {
    Stack() {
      if (this.actionType === 'CardPush') {
        PLVLWInteractSideBarCardPushActionSideBarView()
      }
      if (this.actionType === 'Lottery') {
        PLVLWInteractSideBarLotteryActionSideBarView()
      }
      if (this.actionType === 'Questionnaire') {
        PLVLWInteractSideBarQuestionnaireActionSideBarView()
      }
      if (this.actionType === 'Redpack') {
        PLVLWInteractSideBarRedpackActionSideBarView()
      }
    }
  }
}

@Component
export struct PLVLWInteractSideBarActionPopupViewBuilder {
  actionType: InteractSideBarActionType = lateInit()

  build() {
    Stack() {
      if (this.actionType === 'CardPush') {
        PLVLWInteractSideBarCardPushActionPopupView()
      }
      if (this.actionType === 'Lottery') {
        PLVLWInteractSideBarLotteryActionPopupView()
      }
      if (this.actionType === 'Questionnaire') {
        PLVLWInteractSideBarQuestionnaireActionPopupView()
      }
      if (this.actionType === 'Redpack') {
        PLVLWInteractSideBarRedpackActionPopupView()
      }
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .constraintSize({
      minHeight: 92
    })
  }
}