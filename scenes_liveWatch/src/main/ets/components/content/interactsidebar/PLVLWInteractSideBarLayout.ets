import { PLVCommonConstants } from '@polyvharmony/live-scenes-sdk';
import { lateInit, MutableObserver } from '@polyvharmony/media-player-sdk';
import { InteractSideBarAction, InteractSideBarActionManager } from './actions/interact-side-bar-action-common';
import {
  PLVLWInteractSideBarActionPopupViewBuilder,
  PLVLWInteractSideBarActionSideBarViewBuilder
} from './actions/interact-side-bar-action-view-builder';
import { PLVLWInteractSideBarCardPushAction } from './actions/PLVLWInteractSideBarCardPushAction';
import { PLVLWInteractSideBarLotteryAction } from './actions/PLVLWInteractSideBarLotteryAction';
import { PLVLWInteractSideBarQuestionnaireAction } from './actions/PLVLWInteractSideBarQuestionnaireAction';
import { PLVLWInteractSideBarRedpackAction } from './actions/PLVLWInteractSideBarRedpackAction';

@Component
export struct PLVLWInteractSideBarLayout {
  layoutStyle: 'portrait' | 'landscape' = 'portrait'

  build() {
    if (this.layoutStyle === 'portrait') {
      PLVLWInteractSideBarLayoutPort()
    } else {
      PLVLWInteractSideBarLayoutLand()
    }
  }
}

@Component
struct PLVLWInteractSideBarLayoutPort {
  @Provide('sideBarActionManager') sideBarActionManager: InteractSideBarActionManager = new InteractSideBarActionManager()
  @State private sideBarActions: InteractSideBarAction[] = []
  @State private moreButtonVisible: boolean = false
  private readonly moreActionController = new CustomDialogController({
    builder: SideBarMoreActionCustomDialog(),
    alignment: DialogAlignment.Bottom,
    customStyle: true
  })
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sideBarActionManager.actionsShowInSideBar.observe(it => this.sideBarActions = it).pushTo(this.observers)
    this.sideBarActionManager.sideBarMoreButtonVisible.observe(it => this.moreButtonVisible = it).pushTo(this.observers)
    this.sideBarActionManager.closeMoreActionDialog = () => {
      this.moreActionController.close()
    }
  }

  build() {
    Stack() {
      // register actions
      Stack() {
        PLVLWInteractSideBarCardPushAction()
        PLVLWInteractSideBarLotteryAction()
        PLVLWInteractSideBarQuestionnaireAction()
        PLVLWInteractSideBarRedpackAction()
      }

      // views
      Column() {

        Blank()

        Text($r('app.string.plvlw_interact_side_bar_more'))
          .width(36)
          .height(16)
          .fontSize(10)
          .fontColor($r('app.color.plvlw_interact_side_bar_more_text'))
          .borderRadius(20)
          .backgroundColor($r('app.color.plvlw_interact_side_bar_more_background_solid'))
          .borderColor($r('app.color.plvlw_interact_side_bar_more_background_stroke'))
          .borderWidth(1)
          .textAlign(TextAlign.Center)
          .visibility(this.moreButtonVisible ? Visibility.Visible : Visibility.None)
          .onClick(() => {
            this.moreActionController.open()
          })

        ForEach(
          this.sideBarActions.slice().reverse(),
          (action: InteractSideBarAction) => {
            PLVLWInteractSideBarActionSideBarViewBuilder({
              actionType: action.type
            })
          },
          (action: InteractSideBarAction) => action.type
        )
      }
      .height('100%')
      .onAreaChange((oldArea, newArea) => {
        this.sideBarActionManager.sideBarMaxSize.value = newArea.height as number
      })
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}

@Component
struct PLVLWInteractSideBarLayoutLand {
  @Provide('sideBarActionManager') sideBarActionManager: InteractSideBarActionManager = new InteractSideBarActionManager()
  @State private sideBarActions: InteractSideBarAction[] = []
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sideBarActionManager.availableActions.observe(it => this.sideBarActions = it).pushTo(this.observers)
  }

  build() {
    Row({ space: 8 }) {
      // register actions
      Stack() {
        PLVLWInteractSideBarCardPushAction()
        PLVLWInteractSideBarLotteryAction()
        PLVLWInteractSideBarQuestionnaireAction()
        PLVLWInteractSideBarRedpackAction()
      }

      // views
      ForEach(
        this.sideBarActions.slice().reverse(),
        (action: InteractSideBarAction) => {
          PLVLWInteractSideBarActionSideBarViewBuilder({
            actionType: action.type
          })
        },
        (action: InteractSideBarAction) => action.type
      )
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}

@CustomDialog
struct SideBarMoreActionCustomDialog {
  controller: CustomDialogController = lateInit()
  @Consume('sideBarActionManager') sideBarActionManager: InteractSideBarActionManager
  @State private sideBarActions: InteractSideBarAction[] = []
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sideBarActionManager.availableActions.observe(it => this.sideBarActions = it).pushTo(this.observers)
  }

  build() {
    RelativeContainer() {
      Text($r('app.string.plvlw_live_more_interact'))
        .id('plvlw_interact_side_bar_more_title')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.plvlw_more_setting_action_popup_layout_title'))
        .alignRules({
          middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center },
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top }
        })
        .margin({
          top: 15
        })

      Flex({
        direction: FlexDirection.Row,
        wrap: FlexWrap.Wrap
      }) {
        ForEach(
          this.sideBarActions,
          (action: InteractSideBarAction) => {
            PLVLWInteractSideBarActionPopupViewBuilder({
              actionType: action.type
            }).width('20%')
          },
          (action: InteractSideBarAction) => action.type
        )
      }
      .alignRules({
        top: { anchor: 'plvlw_interact_side_bar_more_title', align: VerticalAlign.Bottom },
        bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
      })
      .margin({
        top: 27,
        bottom: 16
      })
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(282)
    .backgroundColor($r('app.color.plvlw_common_popup_background'))
    .borderRadius({
      topLeft: 16,
      topRight: 16
    })
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}