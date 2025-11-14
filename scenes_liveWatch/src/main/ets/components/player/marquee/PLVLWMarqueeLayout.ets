import { PLVHttpRequest, PLVLiveSceneSDK, PLVResponseType } from '@polyvharmony/live-scenes-sdk';
import {
  decodeFromJson,
  extendNumber,
  extendString,
  isTextEmpty,
  lateInit,
  md5,
  MutableObserver,
  PLVLiveChannelJsonVO,
  PLVMediaPlayerPlayingState,
  seconds,
  watchStates
} from '@polyvharmony/media-player-sdk';
import { PLVMarqueeAnimateSettingVO, PLVMarqueeAnimateType } from './model/PLVMarqueeAnimateSettingVO';
import { PLVMarqueeModel, PLVMarqueePlayingState } from './model/PLVMarqueeModel';
import { PLVMarqueeTextSettingVO } from './model/PLVMarqueeTextSettingVO';
import { PLVMarqueeView } from './PLVMarqueeView';

@Component
export struct PLVLWMarqueeLayout {
  sdk: PLVLiveSceneSDK = lateInit()
  @State private marqueeModel: PLVMarqueeModel | undefined = undefined
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    watchStates(() => {
      const player = this.sdk.playerManager.mainMediaPlayer
      const channelJson = player.getBusinessListenerRegistry().liveChannelJson.value
      if (channelJson) {
        this.resolveMarquee(channelJson)
      }
    }).pushTo(this.observers)
    watchStates(() => {
      const isPlaying = this.sdk.playerManager.mainMediaPlayer.getStateListenerRegistry()
        .playingState
        .value === PLVMediaPlayerPlayingState.PLAYING
      this.marqueeModel?.setPlayingState(isPlaying ? PLVMarqueePlayingState.PLAY : PLVMarqueePlayingState.PAUSE)
    }).pushTo(this.observers)
  }

  build() {
    if (this.marqueeModel) {
      PLVMarqueeView({
        model: this.marqueeModel
      })
    }
  }

  private resolveMarquee(channelJson: PLVLiveChannelJsonVO) {
    if (!this.checkMarqueeSignature(channelJson)) {
      this.onMarqueeSignatureCheckFailed()
      return
    }
    switch (channelJson.marqueeType) {
      case "fixed":
      case "nickname":
        this.resolveMarqueeFixed(channelJson)
        break;
      case "diyurl":
        this.resolveMarqueeCustom(channelJson)
        break;
      default:
        this.marqueeModel = undefined;
        break;
    }
  }

  private checkMarqueeSignature(channelJson: PLVLiveChannelJsonVO): boolean {
    const sign = md5(`${channelJson.marquee}${channelJson.marqueeFontColor}${channelJson.marqueeFontSize}${channelJson.marqueeOpacity}${channelJson.marqueeType}`)
    return isTextEmpty(channelJson.marqueeSign) || sign == channelJson.marqueeSign
  }

  private resolveMarqueeFixed(channelJson: PLVLiveChannelJsonVO) {
    const animSetting = new PLVMarqueeAnimateSettingVO()
    const mainTextSetting = new PLVMarqueeTextSettingVO()
    let subTextSetting: PLVMarqueeTextSettingVO | undefined = undefined

    let marqueeContent = channelJson.marquee ?? ''
    if (channelJson.marqueeType == 'nickname') {
      marqueeContent = this.sdk.channelData.viewerName ?? ''
    }
    const fontSize = extendNumber(channelJson.marqueeFontSize ?? 66).coerceIn_ext(12, 98)

    animSetting.animateType = channelJson.marqueeSetting as PLVMarqueeAnimateType
    animSetting.rollTime = seconds((channelJson.marqueeSpeed ?? 200) / 10)
    animSetting.rollInterval = seconds(5)
    animSetting.tweenTime = seconds(3)
    animSetting.tweenInterval = seconds(5)

    mainTextSetting.content = marqueeContent
    mainTextSetting.fontColor = channelJson.marqueeFontColor ?? '#000000'
    mainTextSetting.fontSize = fontSize
    mainTextSetting.fontAlpha = parseFloat(channelJson.marqueeOpacity?.replace("%", "") ?? '100') / 100

    switch (channelJson.marqueeSetting) {
      case PLVMarqueeAnimateType.ROLL_DOUBLE_MARQUEE:
      case PLVMarqueeAnimateType.FLICKER_DOUBLE_MARQUEE:
        subTextSetting = new PLVMarqueeTextSettingVO()
        subTextSetting.content = marqueeContent
        subTextSetting.fontColor = '#05000000'
        subTextSetting.fontSize = fontSize
        subTextSetting.isShadow = true
        subTextSetting.shadowColor = '#05FFFFFF'
        subTextSetting.shadowRadius = 3
        break;
      default:
    }

    this.marqueeModel = new PLVMarqueeModel(animSetting, mainTextSetting, subTextSetting)
  }

  private async resolveMarqueeCustom(channelJson: PLVLiveChannelJsonVO) {
    const channelId = this.sdk.channelData.loginChannelId!
    const userId = this.sdk.channelData.userId!
    const code = ""
    const timestamp = Date.now().toString()
    const url = extendString(channelJson.marquee).setUrlQueryParam_ext({
      "vid": channelId,
      "uid": userId,
      "code": code,
      "t": timestamp
    })
    const marqueeDataResponse: PLVResponseType<string> = await new PLVHttpRequest().get({
      url: url
    })
    const marqueeData = decodeFromJson(marqueeDataResponse.data, MarqueeDataCustom)
    if (!marqueeData.checkSignature(channelId, userId, code, timestamp)) {
      this.onMarqueeSignatureCheckFailed()
      return
    }
    if (marqueeData.show != "on") {
      this.marqueeModel = undefined
      return
    }

    const animSetting = new PLVMarqueeAnimateSettingVO()
    const mainTextSetting = new PLVMarqueeTextSettingVO()
    let subTextSetting: PLVMarqueeTextSettingVO | undefined = undefined

    const fontSize = extendNumber(marqueeData.fontSize ?? 30).coerceIn_ext(12, 98)
    const marqueeContent = marqueeData.username ?? ''

    animSetting.animateType = marqueeData.setting as PLVMarqueeAnimateType
    animSetting.rollTime = seconds((marqueeData.speed ?? 200) / 10)
    animSetting.rollInterval = seconds(marqueeData.interval ?? 5)
    animSetting.tweenTime = seconds((marqueeData.lifeTime ?? 3) + (marqueeData.tweenTime ?? 1))
    animSetting.tweenInterval = seconds(marqueeData.interval ?? 5)

    mainTextSetting.content = marqueeContent
    mainTextSetting.fontColor = marqueeData.fontColor ?? '#000000'
    mainTextSetting.fontSize = fontSize
    mainTextSetting.fontAlpha = marqueeData.alpha ?? 1
    mainTextSetting.isShadow = marqueeData.filter == "on"
    mainTextSetting.shadowColor = marqueeData.filterColor ?? '#000000'
    mainTextSetting.shadowOffsetX = marqueeData.blurX ?? 2
    mainTextSetting.shadowOffsetY = marqueeData.blurY ?? 2
    mainTextSetting.shadowRadius = marqueeData.strength ?? 4

    switch (channelJson.marqueeSetting) {
      case PLVMarqueeAnimateType.ROLL_DOUBLE_MARQUEE:
      case PLVMarqueeAnimateType.FLICKER_DOUBLE_MARQUEE:
        subTextSetting = new PLVMarqueeTextSettingVO()
        subTextSetting.content = marqueeContent
        subTextSetting.fontColor = '#05000000'
        subTextSetting.fontSize = fontSize
        subTextSetting.isShadow = true
        subTextSetting.shadowColor = '#05FFFFFF'
        subTextSetting.shadowRadius = 3
        break;
      default:
    }

    this.marqueeModel = new PLVMarqueeModel(animSetting, mainTextSetting, subTextSetting)
  }

  private onMarqueeSignatureCheckFailed() {
    this.marqueeModel = undefined
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

class MarqueeDataCustom {
  username?: string
  sign?: string
  msg?: string
  fontSize?: number
  fontColor?: string
  speed?: number
  filter?: string
  setting?: number
  alpha?: number
  filterAlpha?: number
  filterColor?: string
  blurX?: number
  blurY?: number
  interval?: number
  lifeTime?: number
  tweenTime?: number
  strength?: number
  show?: string

  checkSignature(channelId: string, userId: string, code: string, timestamp: string): boolean {
    const param = "vid=" + channelId +
      "&uid=" + userId +
      "&username=" + this.username +
      "&code=" + code +
      "&t=" + timestamp +
      "&msg=" + this.msg +
      "&fontSize=" + this.fontSize +
      "&fontColor=" + this.fontColor +
      "&speed=" + this.speed +
      "&filter=" + this.filter +
      "&setting=" + this.setting +
      "&alpha=" + this.alpha +
      "&filterAlpha=" + this.filterAlpha +
      "&filterColor=" + this.filterColor +
      "&blurX=" + this.blurX +
      "&blurY=" + this.blurY +
      "&interval=" + this.interval +
      "&lifeTime=" + this.lifeTime +
      "&tweenTime=" + this.tweenTime +
      "&strength=" + this.strength +
      "&show=" + this.show;
    const sign = md5(param)
    return sign == this.sign
  }
}