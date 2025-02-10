import { PLVLiveSceneSDK, PLVSocketStatus, PLVSocketStatusSup, PLVToastUtils } from '@polyvharmony/live-scenes-sdk';
import { MutableObserver, requireNotNull } from '@polyvharmony/media-player-sdk';
import { display, mediaquery, router, window } from '@kit.ArkUI';
import { PLVSAPageDataBus, PLVSAStreamerStage } from './common/PLVSAPageDataBus';
import { PLVSALinkMicFullScreenLayout, PLVSALinkMicLayout } from './components/linkmic/PLVSALinkMicLayout';
import { PLVSAStartUpLayout } from './layouts/startup/PLVSAStartUpLayout';
import { PLVSALiveLayout } from './layouts/live/PLVSALiveLayout';
import { PLVSALiveEndLayout } from './layouts/end/PLVSALiveEndLayout';
import { PLVSAConfirmDialog } from './common/widget/PLVSAConfirmDialog';
import { common } from '@kit.AbilityKit';

const STREAMER_ALONE_PAGE_NAME = "PLVSAStreamerAlonePage"

class StreamerAlonePayload {
  readonly sdkId: number

  constructor(sdkId: number) {
    this.sdkId = sdkId
  }
}

export function routerToStreamerAlone(sdk: PLVLiveSceneSDK) {
  const param = new StreamerAlonePayload(sdk.uniqueId)
  router.pushNamedRoute({
    name: STREAMER_ALONE_PAGE_NAME,
    params: param
  })
}

@Entry({
  routeName: STREAMER_ALONE_PAGE_NAME
})
@Component
struct PLVSAStreamerAlonePage {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = requireNotNull(PLVLiveSceneSDK.get((router.getParams() as StreamerAlonePayload).sdkId))
  @Provide('pageDataBus') pageDataBus: PLVSAPageDataBus = new PLVSAPageDataBus()
  @State stage: PLVSAStreamerStage = PLVSAStreamerStage.STARTUP
  @State isPortrait: boolean = true
  private exitDialogController: CustomDialogController | null = null
  private readonly queryOrientation = mediaquery.matchMediaSync('(orientation: landscape)');
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.setKeepScreenOn(true)
    this.sdk.initData(getContext() as common.UIAbilityContext)
    this.loginSocket()
    this.queryOrientation.on("change", () => {
      this.updateOrientation()
    })
    this.pageDataBus.recoverSetting.channelId = this.sdk.channelData.loginChannelId
    this.pageDataBus.streamerStage.observe(it => this.stage = it).pushTo(this.observers)
    this.pageDataBus.isPortrait.observe(it => this.isPortrait = it).pushTo(this.observers)
  }

  build() {
    Stack() {
      Image(this.isPortrait ? $r('app.media.plvsa_streamer_page_bg_port') : $r('app.media.plvsa_streamer_page_bg_land'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      PLVSALinkMicLayout()

      if (this.stage === PLVSAStreamerStage.STARTUP) {
        PLVSAStartUpLayout()
      } else if (this.stage === PLVSAStreamerStage.LIVE) {
        PLVSALiveLayout()
          .hitTestBehavior(HitTestMode.Transparent)
      } else if (this.stage === PLVSAStreamerStage.END) {
        PLVSALiveEndLayout()
      }

      PLVSALinkMicFullScreenLayout()
    }
  }

  private loginSocket() {
    this.sdk.socketManager.onStatus((status: PLVSocketStatusSup) => {
      switch (status.socketStatus) {
        case PLVSocketStatus.RECONNECTING:
          PLVToastUtils.shortShow($r('app.string.plvsa_chat_toast_reconnecting'))
          break;
        case PLVSocketStatus.RECONNECT_SUCCESS:
          PLVToastUtils.shortShow($r('app.string.plvsa_chat_toast_reconnect_success'))
          break;
        case PLVSocketStatus.LOGIN_FAIL:
          getContext().resourceManager.getStringValue($r('app.string.plvsa_chat_toast_login_failed'))
            .then((value) => {
              PLVToastUtils.shortShow(`${value}: message=${status.error?.message}`)
            })
          break;
        case PLVSocketStatus.BE_KICKED_OUT:
          this.exitWithDialog($r('app.string.plvsa_chat_toast_been_kicked'))
          break
        case PLVSocketStatus.LOGIN_REFUSE:
          this.exitWithDialog($r('app.string.plvsa_chat_toast_been_kicked'))
          break
        case PLVSocketStatus.LOGIN_ELSEWHERE:
          this.exitWithDialog($r('app.string.plvsa_chat_toast_account_login_elsewhere'))
          break
        default:
          break;
      }
    }, this)
    this.sdk?.socketManager.login()
  }

  private exitWithDialog(content: string | Resource) {
    this.sdk.linkmicManager.leaveLinkMic()
    this.sdk.streamerManager.finishStream()
    this.exitDialogController = new CustomDialogController({
      builder: PLVSAConfirmDialog({
        content: content,
        hasCancel: false,
        onClickConfirm: (controller) => {
          this.pageDataBus.finishStream(this.sdk)
          controller?.close()
        }
      }),
      autoCancel: false,
      customStyle: true
    })
    this.exitDialogController.open()
  }

  private updateOrientation() {
    const orientation = display.getDefaultDisplaySync().orientation
    this.pageDataBus.isPortrait.value = orientation === display.Orientation.PORTRAIT || orientation === display.Orientation.PORTRAIT_INVERTED
  }

  onBackPress(): boolean | void {
    return this.pageDataBus.onBackPressHandler.onBackPress()
  }

  aboutToDisappear(): void {
    this.setKeepScreenOn(false)
    this.queryOrientation.off("change")
    MutableObserver.disposeAll(this.observers)
    this.observers = []
    this.sdk.destroy()
  }

  private async setKeepScreenOn(keepScreenOn: boolean) {
    const lastWindow = await window.getLastWindow(getContext(this));
    lastWindow.setWindowKeepScreenOn(keepScreenOn);
  }
}