import { PLVCommonConstants, PLVLiveSceneSDK, PLVTimeUtils } from '@polyvharmony/live-scenes-sdk'
import { lateInit, MutableObserver, watchStates } from '@polyvharmony/media-player-sdk'
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus'

// <editor-fold defaultstate="collapsed" desc="UI样式常量定义">
const SLIDER_BACKGROUND_COLOR = '#33FFFFFF'
const SLIDER_PROGRESS_COLOR_NORMAL = '#FFFFFF'
const SLIDER_THUMB_COLOR = '#FFFFFF'
const SLIDER_HEIGHT_NORMAL = 4
const SLIDER_HEIGHT_ON_DRAG = 8
const SLIDER_RADIUS_NORMAL = 4
const SLIDER_RADIUS_ON_DRAG = 8
const THUMB_WIDTH_NORMAL = 8
const THUMB_HEIGHT_NORMAL = 8
const THUMB_RADIUS_NORMAL = 8
const THUMB_WIDTH_ON_DRAG = 8
const THUMB_HEIGHT_ON_DRAG = 14
const THUMB_RADIUS_ON_DRAG = 4

// </editor-fold>

@Component
export struct PLVLWPlayerControllerProgressLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private currentTime: number = 0
  @State private duration: number = 0
  @State private isDragging: boolean = false
  @State private isLocked: boolean = false
  private seekPosition: number = 0
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    watchStates(() => {
      const player = this.mainMediaPlayer()
      this.currentTime = player.getStateListenerRegistry().progressState.value ?? 0
      this.duration = player.getStateListenerRegistry().durationState.value ?? 0
      this.isLocked = this.layoutDataBus.playerControllerStatus.value?.locked ?? false
    }).pushTo(this.observers)
  }

  build() {
    RelativeContainer() {
      Text(PLVTimeUtils.generateTime(this.currentTime, true))
        .id('plvlw_player_controller_progress_current_time_text')
        .fontSize(10)
        .fontColor($r('app.color.plvlw_player_progress_text'))
        .alignRules({
          start: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
          center: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Center }
        })

      Slider({
        value: this.currentTime,
        min: 0,
        max: this.duration,
        direction: Axis.Horizontal
      })
        .id('plvlw_player_controller_progress_bar')
        .trackColor(SLIDER_BACKGROUND_COLOR)
        .trackThickness(this.isDragging ? SLIDER_HEIGHT_ON_DRAG : SLIDER_HEIGHT_NORMAL)
        .trackBorderRadius(this.isDragging ? SLIDER_RADIUS_ON_DRAG : SLIDER_RADIUS_NORMAL)
        .selectedColor(SLIDER_PROGRESS_COLOR_NORMAL)
        .blockStyle({
          type: SliderBlockType.SHAPE,
          shape: new Rect()
            .width(this.isDragging ? THUMB_WIDTH_ON_DRAG : THUMB_WIDTH_NORMAL)
            .height(this.isDragging ? THUMB_HEIGHT_ON_DRAG : THUMB_HEIGHT_NORMAL)
            .radius(this.isDragging ? THUMB_RADIUS_ON_DRAG : THUMB_RADIUS_NORMAL)
        })
        .blockSize({
          width: this.isDragging ? THUMB_WIDTH_ON_DRAG : THUMB_WIDTH_NORMAL,
          height: this.isDragging ? THUMB_HEIGHT_ON_DRAG : THUMB_HEIGHT_NORMAL
        })
        .blockColor(SLIDER_THUMB_COLOR)
        .onTouch((event)=>{
          event.stopPropagation()
        })
        .hitTestBehavior(this.isLocked ? HitTestMode.None : HitTestMode.Transparent)
        .onChange((value: number, mode: SliderChangeMode) => {
          switch (mode) {
            case SliderChangeMode.Begin:
              this.isDragging = true;
              this.seekPosition = value;
              break;
            case SliderChangeMode.Moving:
              this.isDragging = true;
              this.seekPosition = value;
              break;
            case SliderChangeMode.End:
              this.isDragging = false;
              this.mainMediaPlayer().seek(this.seekPosition)
              break;
            case SliderChangeMode.Click:
              this.isDragging = false;
              this.mainMediaPlayer().seek(value)
              break;
          }
        })
        .alignRules({
          start: { anchor: 'plvlw_player_controller_progress_current_time_text', align: HorizontalAlign.End },
          end: { anchor: 'plvlw_player_controller_progress_duration_text', align: HorizontalAlign.Start },
          center: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Center }
        })

      Text(PLVTimeUtils.generateTime(this.duration, true))
        .id('plvlw_player_controller_progress_duration_text')
        .fontSize(10)
        .fontColor($r('app.color.plvlw_player_progress_text'))
        .alignRules({
          end: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End },
          center: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Center }
        })
    }
    .height(36)
  }

  private mainMediaPlayer() {
    return this.sdk.playerManager.mainMediaPlayer
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}