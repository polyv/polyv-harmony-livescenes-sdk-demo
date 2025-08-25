import { PLVChannelData, PLVCommonConstants, PLVLiveSceneSDK, PLVPreviousContent, PLVPreviousManager, PLVSelPreviousData, PLVStatefulData } from '@polyvharmony/live-scenes-sdk';
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus';
import { PLVLWWaveLoadingView } from '../widget/PLVLWWaveLoadingView';

@Component
export struct PLVLWPreviousTabLayout {
  @State @Require previousTabData?: PreviousTabData = undefined
  @State isDialogStyle: boolean = false
  private previousManager?: PLVPreviousManager = undefined
  @State previousListData?: PLVStatefulData<PLVPreviousContent[]> = undefined
  @State selPreviousData?: PLVSelPreviousData = undefined
  @State isLoading: boolean = false
  @State titleUnselColor?: ResourceColor = undefined
  @State startTimeUnselColor?: ResourceColor = undefined

  aboutToAppear(): void {
    this.initLayoutStyle()
    this.onPreviousData()
  }

  build() {
    Stack() {
      List({ space: 12 }) {
        ForEach(this.previousListData?.data, (item: PLVPreviousContent, index) => {
          ListItem() {
            RelativeContainer() {
              Image(item.firstImage)
                .width(104)
                .height(PLVCommonConstants.FULL_PERCENT)
                .borderRadius(4)
                .id('firstImage')
              Text(item.duration)
                .fontSize(11)
                .fontColor($r('app.color.plvlw_neutral_dark_white'))
                .fontWeight(FontWeight.Bold)
                .margin({ right: 4, bottom: 4 })
                .alignRules({
                  right: { anchor: 'firstImage', align: HorizontalAlign.End },
                  bottom: { anchor: 'firstImage', align: VerticalAlign.Bottom }
                })
              if (this.selPreviousData?.index === index) {
                Row() {
                  PLVLWWaveLoadingView({
                    viewColor: $r('app.color.plvlw_neutral_dark_white')
                  })
                  Text($r('app.string.plvlw_player_playing'))
                    .fontSize(10)
                    .fontColor($r('app.color.plvlw_neutral_dark_white'))
                }
                .justifyContent(FlexAlign.Center)
                .alignItems(VerticalAlign.Center)
                .backgroundColor($r('app.color.plvlw_function_color_red'))
                .borderColor($r('app.color.plvlw_neutral_dark_white'))
                .borderRadius(2)
                .borderWidth(1)
                .width(54)
                .height(18)
                .alignRules({
                  middle: { anchor: 'firstImage', align: HorizontalAlign.Center },
                  center: { anchor: 'firstImage', align: VerticalAlign.Center }
                })
              }
              Column({ space: 5 }) {
                Text(item.title)
                  .fontColor(this.selPreviousData?.index === index ? $r('app.color.plvlw_theme_bg_blue') : this.titleUnselColor)
                  .fontSize(14)
                  .maxLines(1)
                  .wordBreak(WordBreak.BREAK_ALL)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(item.startTime)
                  .fontColor(this.selPreviousData?.index === index ? $r('app.color.plvlw_theme_bg_blue') : this.startTimeUnselColor)
                  .fontSize(12)
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 8 })
              .alignRules({
                center: { anchor: 'firstImage', align: VerticalAlign.Center },
                left: { anchor: 'firstImage', align: HorizontalAlign.End }
              })
            }
            .width(PLVCommonConstants.FULL_PERCENT)
            .height(58)
            .onClick(() => {
              this.previousManager?.changeSelPreviousIndex(index)
            })
          }
        })
        ListItem() {
          this.footer()
        }
      }
      .onScrollIndex((start: number, end: number) => {
        if (!this.previousListData?.data || this.previousManager?.isNoMoreData) {
          return
        }
        if (end >= this.previousListData.data.length - 1) {
          this.isLoading = true
          this.previousManager?.requestPreviousList()
        }
      })
      .scrollBar(BarState.Off)
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)
    }
    .padding({ left: 16, right: 16, top: 16 })
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
  }

  initLayoutStyle() {
    this.titleUnselColor = this.isDialogStyle ? $r('app.color.plvlw_neutral_light_black_80') : $r('app.color.plvlw_neutral_dark_white_80')
    this.startTimeUnselColor = this.isDialogStyle ? $r('app.color.plvlw_neutral_light_black_40') : $r('app.color.plvlw_neutral_dark_white_40')
  }

  onPreviousData() {
    this.previousManager = this.previousTabData?.sdk?.previousManager
    this.previousManager?.previousListPromise.observe((data) => {
      if (data.isSuccess) {
        this.previousListData = data
      }
      this.isLoading = false
    })
    this.previousManager?.selPreviousDataPromise.observe((data) => {
      this.selPreviousData = data
    })
  }

  @Builder
  footer() {
    Row() {
      LoadingProgress()
        .height(32)
        .width(48)
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(64)
    .justifyContent(FlexAlign.Center)
    .visibility(this.isLoading ? Visibility.Visible : Visibility.None)
  }
}

export class PreviousTabData {
  sdk?: PLVLiveSceneSDK = undefined
  channelData?: PLVChannelData = undefined
  layoutDataBus?: PLVLWLayoutDataBus

  constructor(sdk?: PLVLiveSceneSDK, channelData?: PLVChannelData, layoutDataBus?: PLVLWLayoutDataBus) {
    this.sdk = sdk
    this.channelData = channelData
    this.layoutDataBus = layoutDataBus
  }
}