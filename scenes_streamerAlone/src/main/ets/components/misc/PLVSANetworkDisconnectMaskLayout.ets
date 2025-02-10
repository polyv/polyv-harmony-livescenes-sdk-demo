import { componentUtils } from '@kit.ArkUI'
import { PLVLiveSceneSDK, PLVNetworkQuality } from '@polyvharmony/live-scenes-sdk'
import { derivedStateOf, lateInit, MutableObserver, Rect } from '@polyvharmony/media-player-sdk'
import { PLVSAPageDataBus } from '../../common/PLVSAPageDataBus'

@Component
export struct PLVSANetworkDisconnectMaskLayout {
  callbackOnTouchIntercept: (callback: (event: TouchEvent) => HitTestMode) => void = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('pageDataBus') pageDataBus: PLVSAPageDataBus
  @State private isVisible: boolean = false
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D({ antialias: true })
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.callbackOnTouchIntercept((event) => this.handleOnTouchIntercept(event))
    const networkDisconnectedState = derivedStateOf<boolean>(() => {
      const networkQuality = this.sdk.linkmicManager.linkmicNetworkQuality.value
      if (networkQuality === PLVNetworkQuality.DISCONNECT) {
        return true
      }
      if (networkQuality === PLVNetworkQuality.UNKNOWN) {
        const networkStatistics = this.sdk.linkmicManager.linkmicNetworkStatistics.value
        const delay = networkStatistics?.upDelayMs ?? 0
        if (delay < 0) {
          return true
        }
      }
      return false
    })
    networkDisconnectedState.observe((disconnected) => {
      this.isVisible = disconnected
    }).pushTo(this.observers)
    networkDisconnectedState.relayTo(this.pageDataBus.networkDisconnectedMaskVisible).pushTo(this.observers)
  }

  build() {
    if (this.isVisible) {
      Stack() {
        Canvas(this.context)
          .width('100%')
          .height('100%')
          .onReady(() => {
            this.drawMask()
          })

        Column() {
          Image($r('app.media.plvsa_network_disconnect_mask_icon'))
            .width(64)
            .height(64)

          Text($r('app.string.plvsa_network_disconnect_mask_hint'))
            .fontSize(16)
            .fontColor('#FFFFFF')
            .margin({
              top: 8
            })
        }
      }
      .width('100%')
      .height('100%')
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }

  private drawMask() {
    this.context.reset()
    const path = new Path2D()
    path.rect(0, 0, this.context.width, this.context.height)
    this.pathCloseIcon(path)
    this.pathNetworkStatusBar(path)
    this.context.clip(path, 'evenodd')
    this.context.fillStyle = '#99000000'
    this.context.fillRect(0, 0, this.context.width, this.context.height)
  }

  private pathCloseIcon(path: Path2D) {
    const maskLayoutInfo = componentUtils.getRectangleById('plvsa_network_disconnect_mask_layout')
    const closeIconInfo = componentUtils.getRectangleById('plvsa_status_bar_finish_stream_icon')
    const offsetX = px2vp(closeIconInfo.screenOffset.x - maskLayoutInfo.screenOffset.x)
    const offsetY = px2vp(closeIconInfo.screenOffset.y - maskLayoutInfo.screenOffset.y)
    const radius = px2vp(closeIconInfo.size.width / 2)
    path.arc(offsetX + radius, offsetY + radius, radius, 0, 2 * Math.PI)
  }

  private pathNetworkStatusBar(outPath: Path2D) {
    const maskLayoutInfo = componentUtils.getRectangleById('plvsa_network_disconnect_mask_layout')
    const networkBarInfo = componentUtils.getRectangleById('plvsa_status_bar_network_bar')
    const offsetX = px2vp(networkBarInfo.screenOffset.x - maskLayoutInfo.screenOffset.x)
    const offsetY = px2vp(networkBarInfo.screenOffset.y - maskLayoutInfo.screenOffset.y)
    const width = px2vp(networkBarInfo.size.width)
    const height = px2vp(networkBarInfo.size.height)
    const radius = 10
    const path = new Path2D()
    path.moveTo(offsetX, offsetY + height / 2)
    path.arcTo(offsetX, offsetY, offsetX + width / 2, offsetY, radius)
    path.arcTo(offsetX + width, offsetY, offsetX + width, offsetY + height / 2, radius)
    path.arcTo(offsetX + width, offsetY + height, offsetX + width / 2, offsetY + height, radius)
    path.arcTo(offsetX, offsetY + height, offsetX, offsetY + height / 2, radius)
    outPath.addPath(path)
  }

  private handleOnTouchIntercept(event: TouchEvent): HitTestMode {
    if (!this.isVisible) {
      return HitTestMode.Transparent
    }
    if (this.isTouchView(event, 'plvsa_status_bar_finish_stream_icon')
      || this.isTouchView(event, 'plvsa_status_bar_network_bar')) {
      return HitTestMode.Transparent
    }
    return HitTestMode.Default
  }

  private isTouchView(event: TouchEvent, id: string) {
    const viewRect = (id: string) => {
      const info = componentUtils.getRectangleById(id)
      return new Rect({
        left: info.windowOffset.x,
        top: info.windowOffset.y,
        right: info.windowOffset.x + info.size.width,
        bottom: info.windowOffset.y + info.size.height
      })
    }
    const x = vp2px(event.touches[0]?.windowX)
    const y = vp2px(event.touches[0]?.windowY)
    return viewRect(id).contains(x, y)
  }
}