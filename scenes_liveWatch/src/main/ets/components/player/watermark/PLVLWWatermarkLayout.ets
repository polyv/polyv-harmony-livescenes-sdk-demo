import { PLVCommonConstants, PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk'
import {
  isTextEmpty,
  lateInit,
  MutableObserver,
  mutableStateOf,
  PLVLiveChannelJsonVO,
  watchStates
} from '@polyvharmony/media-player-sdk'

@Component
export struct PLVLWWatermarkLayout {
  sdk: PLVLiveSceneSDK = lateInit()
  private readonly canvasSettings: RenderingContextSettings = new RenderingContextSettings(true)
  private readonly canvas: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings)
  @State private watermarkAlpha: number = 1
  private readonly canvasReady = mutableStateOf(false)
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    watchStates(() => {
      this.tryDrawWatermark()
    }).pushTo(this.observers)
  }

  build() {
    Canvas(this.canvas)
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)
      .opacity(this.watermarkAlpha)
      .onReady(() => {
        this.canvasReady.setValue(true)
      })
      .onAreaChange(() => {
        this.tryDrawWatermark()
      })
  }

  private tryDrawWatermark() {
    if (this.canvasReady.value) {
      const player = this.sdk.playerManager.mainMediaPlayer
      const channelJson = player.getBusinessListenerRegistry().liveChannelJson.value
      if (channelJson) {
        this.drawWatermark(channelJson)
      }
    }
  }

  private drawWatermark(channelJson: PLVLiveChannelJsonVO) {
    this.canvas.clearRect(0, 0, this.canvas.width, this.canvas.height)
    const showWatermark = channelJson.channelWatermarkModel?.watermarkRestrict == "Y"
    if (!showWatermark) {
      return
    }

    this.prepareCanvas(channelJson)
    let text = channelJson.channelWatermarkModel?.watermarkContent
    if (channelJson.channelWatermarkModel?.watermarkType == 'nickname') {
      text = this.sdk.channelData.viewerName
    }
    if (isTextEmpty(text)) {
      return
    }
    const textMeasure = this.canvas.measureText(text)
    const rotateAngle = 15 * Math.PI / 180
    const patternWidth = textMeasure.width * Math.cos(rotateAngle) + textMeasure.height * Math.sin(rotateAngle) + 30
    const patternHeight = textMeasure.width * Math.sin(rotateAngle) + textMeasure.height * Math.cos(rotateAngle) + 30

    this.canvas.saveLayer()
    this.canvas.rotate(-rotateAngle)
    for (let left = 0; left < this.canvas.width; left += patternWidth) {
      for (let top = 0; top < this.canvas.height; top += patternHeight) {
        const x = left
        const y = top + textMeasure.width * Math.sin(rotateAngle) + textMeasure.height * Math.cos(rotateAngle)
        const rotateX = x * Math.cos(rotateAngle) - y * Math.sin(rotateAngle)
        const rotateY = x * Math.sin(rotateAngle) + y * Math.cos(rotateAngle)
        this.canvas.fillText(text, rotateX, rotateY)
      }
    }
    this.canvas.restoreLayer()
  }

  private prepareCanvas(channelJson: PLVLiveChannelJsonVO) {
    this.watermarkAlpha = 1 - (parseFloat(channelJson.channelWatermarkModel?.watermarkOpacity ?? "0") / 100)

    let fontSize = 20
    switch (channelJson.channelWatermarkModel?.watermarkFontSize) {
      case "large":
        fontSize = 20;
        break;
      case "middle":
        fontSize = 16;
        break;
      case "small":
        fontSize = 12;
        break;
      default:
    }
    this.canvas.font = `normal ${fontSize}vp sans-serif`
    this.canvas.fillStyle = '#000000'
    this.canvas.shadowColor = '#FFFFFF'
    this.canvas.shadowBlur = 1
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}