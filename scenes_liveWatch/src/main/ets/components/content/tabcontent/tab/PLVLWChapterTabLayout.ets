import { PLVChannelData, PLVChapterDataVO, PLVCommonConstants, PLVLiveSceneSDK, PLVPreviousManager, PLVSelChapterData, PLVStatefulData, PLVTimeUtils } from '@polyvharmony/live-scenes-sdk'
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus'
import { PLVLWWaveLoadingView } from '../widget/PLVLWWaveLoadingView'

@Component
export struct PLVLWChapterTabLayout {
  @State @Require chapterTabData?: ChapterTabData = undefined
  @State isDialogStyle: boolean = false
  private previousManager?: PLVPreviousManager = undefined
  @State chapterListData?: PLVStatefulData<PLVChapterDataVO[]> = undefined
  @State mainTextUnselColor?: ResourceColor = undefined
  @State subTextUnselColor?: ResourceColor = undefined
  @State selChapterData?: PLVSelChapterData = undefined

  aboutToAppear() {
    this.initLayoutStyle()
    this.onPreviousData()
  }

  build() {
    Stack() {
      List() {
        ForEach(this.chapterListData?.data, (item: PLVChapterDataVO, index: number) => {
          ListItem() {
            RelativeContainer() {
              Text((index + 1) <= 9 ? "0" + (index + 1) : (index + 1) + "")
                .fontSize(16)
                .fontColor(this.subTextUnselColor)
                .fontWeight(FontWeight.Bold)
                .visibility(this.selChapterData?.index === index ? Visibility.Hidden : Visibility.Visible)
              PLVLWWaveLoadingView({
                viewWidth: 20,
                viewHeight: 20,
                viewColor: $r('app.color.plvlw_theme_bg_blue')
              })
                .visibility(this.selChapterData?.index === index ? Visibility.Visible : Visibility.Hidden)
                .id('waveLoadingView')
              Text(item.title)
                .fontSize(14)
                .maxLines(1)
                .wordBreak(WordBreak.BREAK_ALL)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .fontColor(this.selChapterData?.index === index ? $r('app.color.plvlw_theme_bg_blue') : this.mainTextUnselColor)
                .margin({ left: 12 })
                .alignRules({
                  left: { anchor: 'waveLoadingView', align: HorizontalAlign.End }
                })
                .id('titleText')
              Text(PLVTimeUtils.generateTime(item.timeStamp !== undefined ? item.timeStamp * 1000 : 0, true))
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.selChapterData?.index === index ? $r('app.color.plvlw_theme_bg_blue') : this.subTextUnselColor)
                .margin({ top: 4 })
                .alignRules({
                  left: { anchor: 'titleText', align: HorizontalAlign.Start },
                  top: { anchor: 'titleText', align: VerticalAlign.Bottom }
                })
            }
            .padding({ left: 22, top: 14 })
            .width(PLVCommonConstants.FULL_PERCENT)
            .height(66)
            .onClick(() => {
              this.previousManager?.changeSelChapterIndex(index)
            })
          }
        })
      }
      .scrollBar(BarState.Off)
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)
    }
    .padding({ top: 12 })
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
  }

  initLayoutStyle() {
    this.mainTextUnselColor = this.isDialogStyle ? $r('app.color.plvlw_neutral_light_black') : $r('app.color.plvlw_neutral_dark_white')
    this.subTextUnselColor = this.isDialogStyle ? $r('app.color.plvlw_neutral_light_black_40') : $r('app.color.plvlw_neutral_dark_white_40')
  }

  onPreviousData() {
    this.previousManager = this.chapterTabData?.sdk?.previousManager
    this.previousManager?.chapterListPromise.observe((data) => {
      if (data.isSuccess) {
        this.chapterListData = data
      }
    })
    this.previousManager?.selChapterDataPromise.observe((data) => {
      this.selChapterData = data
    })
  }
}

export class ChapterTabData {
  sdk?: PLVLiveSceneSDK = undefined
  channelData?: PLVChannelData = undefined
  layoutDataBus?: PLVLWLayoutDataBus

  constructor(sdk?: PLVLiveSceneSDK, channelData?: PLVChannelData, layoutDataBus?: PLVLWLayoutDataBus) {
    this.sdk = sdk
    this.channelData = channelData
    this.layoutDataBus = layoutDataBus
  }
}