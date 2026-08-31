import { PLVCommonConstants, PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk'
import { lateInit, MutableObserver } from '@polyvharmony/media-player-sdk'
import { PLVLWLayoutDataBus } from '../../../../../common/PLVLWLayoutDataBus'
import { PLVLWPiPManager } from '../../../../../common/PLVLWPiPManager'
import { MoreSettingActionCallback, MoreSettingActionView } from './more-setting-action-common'

@Component
export struct PLVLWMorePlaySettingAction {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('moreSettingActionCallback') moreSettingActionCallback: MoreSettingActionCallback
  @State private isVisible: boolean = false
  private readonly playSettingDialog = new CustomDialogController({
    builder: PLVLWMorePlaySettingDialog(),
    alignment: DialogAlignment.BottomEnd,
    customStyle: true
  })

  aboutToAppear(): void {
    this.isVisible = this.sdk.channelData.liveDetail?.isFenestrulePlayEnabled() ?? false
  }

  build() {
    MoreSettingActionView({
      icon: $r('app.media.plvlw_more_play_setting_icon'),
      title: $r('app.string.plvlw_live_play_setting')
    })
      .onClick(() => {
        this.moreSettingActionCallback.hideMoreSettingDialog?.()
        this.playSettingDialog.open()
      })
      .visibility(this.isVisible ? Visibility.Visible : Visibility.None)
  }
}

@CustomDialog
struct PLVLWMorePlaySettingDialog {
  controller: CustomDialogController = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private isPortrait: boolean = true
  @State private exitRoomAutoPiPEnabled: boolean = true
  @State private backgroundAutoPiPEnabled: boolean = true
  @State private showBackgroundAutoPiPSetting: boolean = true
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.layoutDataBus.isPortrait.observe((isPortrait: boolean) => {
      this.isPortrait = isPortrait
    }).pushTo(this.observers)
    PLVLWPiPManager.instance.exitRoomAutoPiPEnabled.observe((enabled: boolean) => {
      this.exitRoomAutoPiPEnabled = enabled
      this.showBackgroundAutoPiPSetting = enabled
    }).pushTo(this.observers)
    PLVLWPiPManager.instance.backgroundAutoPiPEnabled.observe((enabled: boolean) => {
      this.backgroundAutoPiPEnabled = enabled
    }).pushTo(this.observers)
  }

  build() {
    Column() {
      Text($r('app.string.plvlw_live_play_setting'))
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(52)
        .textAlign(TextAlign.Center)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.plvlw_more_setting_action_popup_layout_title'))

      Divider()
        .height(1)
        .color('#F2F2F2')

      PLVLWPlaySettingSwitchRow({
        title: $r('app.string.plvlw_live_auto_pip_exit_page'),
        isOn: this.exitRoomAutoPiPEnabled,
        onChange: (enabled: boolean) => {
          // 条件渲染依赖弹窗自身的 @State，需在当前 UI 事件中直接更新。
          // 仅等待 Manager 的 observe 回调会导致关闭后能隐藏、重新开启却不立即创建第二行。
          this.exitRoomAutoPiPEnabled = enabled
          this.showBackgroundAutoPiPSetting = enabled
          PLVLWPiPManager.instance.setExitRoomAutoPiPEnabled(enabled)
        }
      })

      // 保持组件实例存在，只切换可见性。ArkUI V1 的条件分支在 Toggle 事件中被移除后，
      // 同一轮弹窗生命周期里可能不会重新创建该自定义组件。
      PLVLWPlaySettingSwitchRow({
        title: $r('app.string.plvlw_live_auto_pip_go_home'),
        isOn: this.backgroundAutoPiPEnabled,
        onChange: (enabled: boolean) => {
          this.backgroundAutoPiPEnabled = enabled
          PLVLWPiPManager.instance.setBackgroundAutoPiPEnabled(enabled)
        }
      })
        .visibility(this.showBackgroundAutoPiPSetting ? Visibility.Visible : Visibility.None)
    }
    .width(this.isPortrait ? PLVCommonConstants.FULL_PERCENT : 375)
    .height(this.isPortrait ? 266 : PLVCommonConstants.FULL_PERCENT)
    .backgroundColor($r('app.color.plvlw_common_popup_background'))
    .borderRadius({
      topLeft: 16,
      topRight: this.isPortrait ? 16 : 0,
      bottomLeft: this.isPortrait ? 0 : 16
    })
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

@Component
struct PLVLWPlaySettingSwitchRow {
  @Prop title: ResourceStr
  @Prop isOn: boolean = true
  onChange: (enabled: boolean) => void = () => {}

  build() {
    Row() {
      Text(this.title)
        .fontSize(16)
        .fontColor($r('app.color.plvlw_more_setting_action_popup_layout_title'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Blank()

      Toggle({
        type: ToggleType.Switch,
        isOn: this.isOn
      })
        .width(38)
        .height(24)
        .selectedColor('#3F76FC')
        .switchPointColor('#FFFFFF')
        .onChange((enabled: boolean) => this.onChange(enabled))
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(56)
    .padding({
      left: 24,
      right: 24
    })
  }
}
