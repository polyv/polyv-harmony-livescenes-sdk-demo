import { PLVCallback, PLVChannelData, PLVCommonConstants,
  PLVJSONUtils,
  PLVLiveSceneSDK, PLVLogger, PLVLoginType, PLVSimpleWeb, PLVUtils, PLVWebController, PLVWebUtils } from '@polyvharmony/live-scenes-sdk'
import { MutableObserver, PLVLiveStatusEnum, watchStates } from '@polyvharmony/media-player-sdk'
import { PlayStatus, PLVLWCommonDef } from '../../../../common/PLVLWCommonDef'
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus'
import { PLVLWWaveLoadingView } from '.././widget/PLVLWWaveLoadingView'

const TAG = '[PLVLWDescTabLayout]'

@Preview
@Component
export struct PLVLWDescTabLayout {
  @State @Require descTabData?: DescTabData = undefined
  @State isDialogStyle: boolean = false
  @State titleColor?: Resource = undefined
  @State publisherColor?: Resource = undefined
  @State watchingColor?: Resource = undefined
  @State titleLayoutBgColor?: Resource = undefined
  @State webTextColor?: Resource = undefined
  @State dividerColor?: Resource = undefined
  @State webController: PLVWebController = new PLVWebController()
  @State descContent: string | undefined = undefined
  @State startTime: string | undefined = undefined
  @State publisher: ResourceStr | undefined = undefined
  @State statusText: ResourceStr | undefined = undefined
  @State statusColor: ResourceColor | undefined = undefined
  @State statusBgColor: ResourceColor | undefined = undefined
  @State showWvView: boolean = false
  @State pageViewer: number | undefined = undefined
  private currentPlayStatus: PlayStatus | undefined
  private isLayoutVisibleArea: boolean = false
  private backHandler?: PLVCallback<void, boolean>
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.initTabData()
    this.initLayoutStyle()
    this.initWebController()
    this.onPlayerData()
    this.onChannelData()
    this.descTabData?.layoutDataBus?.registerBackPressedHandler(this.backHandler = () => {
      if (this.isLayoutVisibleArea && this.webController.accessBackward()) {
        this.webController.backward()
        return true
      }
      return false
    }, this.isDialogStyle
      ? PLVLWCommonDef.BACK_PRIORITY_GLOBAL_DIALOG_DESC_TAB_CONTENT
      : PLVLWCommonDef.BACK_PRIORITY_DESC_TAB_CONTENT)
  }

  aboutToDisappear(): void {
    this.descTabData?.layoutDataBus?.unregisterBackPressedHandler(this.backHandler)
    MutableObserver.disposeAll(this.observers)
  }

  build() {
    Scroll() {
      Column() {
        RelativeContainer() {
          Image(this.descTabData?.channelData?.liveDetail?.coverImage)
            .alignRules({
              left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
              top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top }
            })
            .width(44)
            .height(44)
            .objectFit(ImageFit.Cover)
            .borderRadius(8)
            .id('coverImage')

          Row() {
            Text(this.descTabData?.channelData?.liveDetail?.name)
              .constraintSize({ maxWidth: this.isDialogStyle ? '100%' : "66%" })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .wordBreak(WordBreak.BREAK_ALL)
              .fontSize(16)
              .fontColor(this.titleColor)
              .fontWeight(FontWeight.Bold)
            if (!this.isDialogStyle) {
              this.statusView()
            }
          }
          .alignRules({
            left: { anchor: 'coverImage', align: HorizontalAlign.End },
            top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top }
          })
          .margin({ left: 12 })
          .height(22)
          .id('titleRow')

          if (this.isDialogStyle) {
            Row({ space: 12 }) {
              this.statusView()
              this.timeView()
            }.alignRules({
              left: { anchor: 'titleRow', align: HorizontalAlign.Start },
              bottom: { anchor: 'coverImage', align: VerticalAlign.Bottom }
            })
          } else {
            this.timeView()
          }

          Divider()
            .alignRules({
              left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
              top: { anchor: "coverImage", align: VerticalAlign.Bottom }
            })
            .vertical(false)
            .margin({ top: 16 })
            .height(1)
            .color(this.dividerColor)
            .id('firstDivider')

          Text() {
            ImageSpan($r('app.media.plvlw_tab_content_publisher'))
              .width(12)
              .height(12)
              .margin({ right: 4 })
              .verticalAlign(ImageSpanAlignment.CENTER)
            Span(!this.publisher ? $r('app.string.plvlw_live_publisher_default') : this.publisher)
          }
          .alignRules({
            left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
            top: { anchor: 'firstDivider', align: VerticalAlign.Bottom }
          })
          .constraintSize({ maxWidth: '60%' })
          .margin({ top: 12 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .wordBreak(WordBreak.BREAK_ALL)
          .fontColor(this.publisherColor)
          .fontSize(12)
          .id('publisherText')

          Text($r('app.string.plvlw_live_room_watch_count', this.pageViewer + ''))
            .alignRules({
              right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End },
              top: { anchor: 'publisherText', align: VerticalAlign.Top }
            })
            .margin({ right: 4 })
            .fontColor(this.watchingColor)
            .fontSize(12)
        }
        .height(122)
        .backgroundColor(this.titleLayoutBgColor)
        .borderRadius(16)
        .padding(16)

        PLVSimpleWeb({ controller: this.webController, src: '' })
          .height(PLVCommonConstants.FULL_PERCENT)
          .margin({ top: 6, bottom: 6 })
      }
    }
    .onVisibleAreaChange([0.0, 1.0], (isExpanding: boolean, currentRatio: number) => {
      this.isLayoutVisibleArea = isExpanding
    })
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
    .scrollBar(BarState.Off)
    .padding({ left: 16, right: 16, top: 12 })
  }

  initLayoutStyle() {
    this.titleColor = this.isDialogStyle ? $r('app.color.plvlw_neutral_light_black_80') : $r('app.color.plvlw_neutral_dark_white')
    this.publisherColor = this.isDialogStyle ? $r('app.color.plvlw_neutral_light_black_60') : $r('app.color.plvlw_neutral_dark_white_80')
    this.watchingColor = this.isDialogStyle ? $r('app.color.plvlw_neutral_light_black_60') : $r('app.color.plvlw_neutral_dark_white_60')
    this.titleLayoutBgColor = this.isDialogStyle ? $r('app.color.plvlw_neutral_light_black_6') : $r('app.color.plvlw_neutral_dark_white_6')
    this.webTextColor = this.isDialogStyle ? $r('app.color.plvlw_web_content_in_dialog_color') : $r('app.color.plvlw_web_content_color')
    this.dividerColor = this.isDialogStyle ? $r('app.color.plvlw_neutral_light_black_20') : $r('app.color.plvlw_neutral_dark_white_6')
  }

  initTabData() {
    this.descContent = this.descTabData?.channelData?.getMenuDescContent()
    this.startTime = this.descTabData?.channelData?.liveDetail?.getStartTime()
    this.publisher = this.descTabData?.channelData?.liveDetail?.getPublisher()
  }

  initWebController() {
    this.webController
      .nestedScrollOptions({
        scrollForward: NestedScrollMode.PARALLEL,
        scrollBackward: NestedScrollMode.SELF_FIRST
      })
      .onControllerAttached(() => {
        this.webController.loadHtmlData(PLVWebUtils.toWebViewContent(this.descContent, PLVUtils.colorResourceToHex(this.webTextColor!)))
      })
  }

  onPlayerData() {
    if (this.descTabData?.channelData?.loginType == PLVLoginType.PLAYBACK) {
      this.changeStatus('playback')
    } else {
      const status = this.descTabData?.channelData?.liveDetail?.watchStatus
      if ("unStart" === status) {
        this.changeStatus('unStart')
      } else if ("waiting" === status) {
        this.changeStatus('waiting')
      }
      watchStates(() => {
        const liveStatus = this.descTabData?.sdk?.playerManager.mainMediaPlayer.getBusinessListenerRegistry()
          .liveStatus
          .value
        // 当直播流状态为END 且 当前状态为 WAIT 或 UNSTART 保持当前状态不变，其余皆更新为直播流状态
        const canChangeStatus = (this.currentPlayStatus !== "waiting" && this.currentPlayStatus !== "unStart") || liveStatus !== PLVLiveStatusEnum.NO_LIVE
        PLVLogger.info(TAG, 'canChangeStatus=' + canChangeStatus + ", liveStatus=" + PLVJSONUtils.safeStringify(liveStatus))
        if (canChangeStatus) {
          switch (liveStatus) {
            case PLVLiveStatusEnum.LIVE:
              this.changeStatus('live')
              break
            case PLVLiveStatusEnum.PAUSE:
              this.changeStatus('stop')
              break
            case PLVLiveStatusEnum.NO_LIVE:
              this.changeStatus('end')
              break
          }
        }
      }).pushTo(this.observers)
    }
  }

  onChannelData() {
    this.pageViewer = this.descTabData?.channelData?.pageViewer
    this.descTabData?.channelData?.eventNotify.on('page_viewer', (arg: number) => {
      this.pageViewer = arg
    }, this)
  }

  changeStatus(status: PlayStatus) {
    this.statusText = PLVLWCommonDef.STATUS_TEXT_MAP.get(status)
    this.statusColor = PLVLWCommonDef.STATUS_COLOR_MAP.get(status)
    this.statusBgColor = PLVLWCommonDef.STATUS_BG_COLOR_MAP.get(status)
    this.showWvView = 'live' === status || 'playback' === status
    this.currentPlayStatus = status
    PLVLogger.info(TAG, 'changeStatus=' + status)
  }

  @Builder
  statusView() {
    Row() {
      if (this.showWvView) {
        PLVLWWaveLoadingView({ viewColor: this.statusColor })
          .margin({ right: 2 })
      }
      Text(this.statusText)
        .fontSize(10)
        .fontColor(this.statusColor)
    }
    .margin({ left: 4 })
    .padding({
      left: 5,
      right: 5,
      top: 3,
      bottom: 3
    })
    .backgroundColor(this.statusBgColor)
    .borderRadius(10)
  }

  @Builder
  timeView() {
    Text(this.startTime ? this.startTime : '- -')
      .alignRules({
        left: { anchor: 'titleRow', align: HorizontalAlign.Start },
        bottom: { anchor: 'coverImage', align: VerticalAlign.Bottom }
      })
      .fontSize(12)
      .fontColor(this.watchingColor)
  }
}

export class DescTabData {
  sdk?: PLVLiveSceneSDK = undefined
  channelData?: PLVChannelData = undefined
  layoutDataBus?: PLVLWLayoutDataBus

  constructor(sdk?: PLVLiveSceneSDK, channelData?: PLVChannelData, layoutDataBus?: PLVLWLayoutDataBus) {
    this.sdk = sdk
    this.channelData = channelData
    this.layoutDataBus = layoutDataBus
  }
}