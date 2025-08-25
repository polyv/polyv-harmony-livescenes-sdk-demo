import {
  FunctionBean as InteractFunctionBean,
  PLVCommonConstants,
  PLVLiveSceneSDK
} from '@polyvharmony/live-scenes-sdk';
import { lateInit, MutableObserver } from '@polyvharmony/media-player-sdk';
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus';
import { MoreSettingActionCallback } from './actions/more-setting-action-common';
import { PLVLWMoreAudioModeAction } from './actions/PLVLWMoreAudioModeAction';
import { PLVLWMoreBitRateAction } from './actions/PLVLWMoreBitRateAction';
import { PLVLWMoreChatOnlyTeacherAction } from './actions/PLVLWMoreChatOnlyTeacherAction';
import { PLVLWMoreInteractDynamicAction } from './actions/PLVLWMoreInteractDynamicAction';
import { PLVLWMoreShowAnnouncementAction } from './actions/PLVLWMoreShowAnnouncementAction';
import { PLVLWMoreSpeedAction } from './actions/PLVLWMoreSpeedAction';
import { PLVLWMoreSwitchLanguageAction } from './actions/PLVLWMoreSwitchLanguageAction';
import { PLVLWMoreSwitchLineAction } from './actions/PLVLWMoreSwitchLineAction';

@Component
export struct PLVLWMoreSettingIcon {
  private readonly controller: CustomDialogController = new CustomDialogController({
    builder: PLVLWMoreSettingDialog(),
    alignment: DialogAlignment.BottomEnd,
    customStyle: true
  })

  build() {
    Image($r('app.media.plvlw_tool_bar_more_icon'))
      .onClick(() => {
        this.controller.open()
      })
  }
}

@CustomDialog
struct PLVLWMoreSettingDialog {
  controller: CustomDialogController = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @Provide('moreSettingActionCallback') moreSettingActionCallback: MoreSettingActionCallback = new MoreSettingActionCallback()
  @State private isPortrait: boolean = true
  @State private interactDynamicActions: InteractFunctionBean[] = []
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.moreSettingActionCallback.hideMoreSettingDialog = () => {
      this.controller.close()
    }
    this.layoutDataBus.isPortrait.observe(it => this.isPortrait = it).pushTo(this.observers)
    this.layoutDataBus.preload.interactDynamicActions.observe(it => {
      this.interactDynamicActions = it?.value?.dataArray ?? []
    })
      .pushTo(this.observers)
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Scroll() {
        Flex({
          direction: FlexDirection.Row,
          wrap: FlexWrap.Wrap
        }) {
          PLVLWMoreChatOnlyTeacherAction()
          PLVLWMoreShowAnnouncementAction()
          PLVLWMoreAudioModeAction()
          if (this.isPortrait) {
            PLVLWMoreBitRateAction()
            PLVLWMoreSpeedAction()
          }
          PLVLWMoreSwitchLineAction()
          PLVLWMoreSwitchLanguageAction()
          ForEach(
            this.interactDynamicActions,
            (action: InteractFunctionBean) => {
              PLVLWMoreInteractDynamicAction({
                interactAction: action
              })
            },
            (action: InteractFunctionBean) => action.event
          )
        }
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
    }
    .width(this.isPortrait ? PLVCommonConstants.FULL_PERCENT : 375)
    .height(this.isPortrait ? 274 : PLVCommonConstants.FULL_PERCENT)
    .backgroundColor($r('app.color.plvlw_common_popup_background'))
    .borderRadius({
      topLeft: 16,
      topRight: this.isPortrait ? 16 : 0,
      bottomLeft: this.isPortrait ? 0 : 16
    })
    .padding({
      top: 12
    })
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}