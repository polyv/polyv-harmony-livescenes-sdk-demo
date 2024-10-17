import { PLVInteractDataBean, PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk'

@Preview
@Component
export struct PLVLIInteractEntranceView {
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  @State isShowQuestionEntrance?: boolean = false
  @State questionText: string | Resource = $r("app.string.plvli_interact_question")

  aboutToAppear(): void {
    this.onInteractData()
  }

  build() {
    if (this.isShowQuestionEntrance) {
      Row() {
        Row() {
          Image($r('app.media.plvli_questionnaire'))
            .width(16)
            .height(16)
          Text(this.questionText)
            .fontColor("#ffffff")
            .fontSize(14)
            .margin({
              left: 4
            })
        }
        .padding({
          left: 10, top: 5, right: 10, bottom: 5
        })
      }
      .backgroundColor("#333439")
      .borderRadius(16)
      .onClick((event) => {
        this.sdk?.interactManager.showQuestionnaire()
      })
    }
  }

  onInteractData() {
    this.sdk?.interactManager.eventDataNotify.on('interact_data', (data: PLVInteractDataBean) => {
      let dataArray = data.callAppEvent?.getDataArray()
      if (!dataArray || dataArray.length == 0) {
        this.isShowQuestionEntrance = false
      }
      dataArray?.forEach((value, index)=> {
        if (value.isShowQuestionnaireEvent()) {
          this.isShowQuestionEntrance = value.isShow ?? false
          if (value.title) {
            this.questionText = value.title
          }
        }
      })
    }, this)
  }


}