import { PLVCommonConstants } from '@polyvharmony/live-scenes-sdk'
import { derivedStateOf, extendArray, extendNumber, mutableStateOf } from '@polyvharmony/media-player-sdk'

export type InteractSideBarActionType = 'CardPush' | 'Lottery' | 'Questionnaire' | 'Redpack' | 'WelfareLottery'

export class InteractSideBarAction {
  type: InteractSideBarActionType
  payload?: Object

  constructor(type: InteractSideBarActionType, payload?: Object) {
    this.type = type
    this.payload = payload
  }
}

export class InteractSideBarActionManager {
  readonly availableActions = mutableStateOf<InteractSideBarAction[]>([])
  readonly sideBarMaxSize = mutableStateOf(0)
  readonly actionsShowInSideBar = derivedStateOf(() => {
    const allActions = this.availableActions.value ?? []
    const sideBarMaxSize = this.sideBarMaxSize.value ?? 0
    const moreButtonSize = 20
    const actionItemSize = 48
    const takeCount = extendNumber(Math.floor((sideBarMaxSize - moreButtonSize) / actionItemSize)).coerceAtLeast_ext(0)
    return allActions.slice(0, takeCount)
  })
  readonly sideBarMoreButtonVisible = derivedStateOf(() => {
    const allActions = this.availableActions.value ?? []
    const sideBarActions = this.actionsShowInSideBar.value ?? []
    return sideBarActions.length < allActions.length
  })
  closeMoreActionDialog?: () => void

  getActionWithType(actionType: InteractSideBarActionType): InteractSideBarAction | undefined {
    return (this.availableActions.value ?? []).find(it => it.type === actionType)
  }

  onActionAvailable(action: InteractSideBarAction) {
    const actions = (this.availableActions.value ?? []).slice()
    if (!actions.find(it => it.type === action.type)) {
      actions.push(action)
    }
    this.availableActions.value = [...actions]
  }

  onActionCancel(actionType: InteractSideBarActionType) {
    const actions = (this.availableActions.value ?? []).slice()
    extendArray(actions).remove_ext(actions.find(it => it.type === actionType))
    this.availableActions.value = [...actions]
  }
}

@Component
export struct InteractSideBarView {
  @Prop icon: ResourceStr
  @Prop title: ResourceStr

  build() {
    RelativeContainer() {
      Image(this.icon)
        .width(36)
        .height(36)
        .alignRules({
          center: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Center },
          middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center }
        })
      Text(this.title)
        .height(12)
        .constraintSize({
          minWidth: 32
        })
        .textAlign(TextAlign.Center)
        .fontSize(8)
        .fontColor($r('app.color.plvlw_interact_side_bar_action_text'))
        .padding(1)
        .borderRadius(6)
        .backgroundColor($r('app.color.plvlw_interact_side_bar_action_text_background'))
        .alignRules({
          bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom },
          middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center }
        })
    }
    .width(36)
    .height(36)
    .borderRadius(4)
    .backgroundColor($r('app.color.plvlw_interact_side_bar_action_background'))
    .margin({
      top: 6,
      bottom: 6
    })
  }
}

@Component
export struct InteractPopupView {
  @Prop icon: ResourceStr
  @Prop iconText: ResourceStr
  @Prop title: ResourceStr

  build() {
    Column() {
      RelativeContainer() {
        Image(this.icon)
          .width(36)
          .height(36)
          .alignRules({
            top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
            middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center }
          })
          .margin({
            top: 2
          })

        Text(this.iconText)
          .height(12)
          .constraintSize({
            minWidth: 32
          })
          .textAlign(TextAlign.Center)
          .fontSize(8)
          .fontColor($r('app.color.plvlw_interact_side_bar_action_text'))
          .padding(1)
          .borderRadius(6)
          .backgroundColor($r('app.color.plvlw_interact_side_bar_action_text_background'))
          .alignRules({
            bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom },
            middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center }
          })
      }
      .width(46)
      .height(46)
      .backgroundColor($r('app.color.plvlw_interact_side_bar_action_background'))
      .borderRadius(5)

      Text(this.title)
        .fontSize(12)
        .fontColor($r('app.color.plvlw_interact_side_bar_action_name'))
        .margin({
          top: 5
        })
        .textAlign(TextAlign.Center)
    }
  }
}