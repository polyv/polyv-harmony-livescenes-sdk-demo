@Component
export struct PLVSAPreferenceCardView {
  @BuilderParam slot: () => void = this.noopSlot
  @Prop selected: boolean = false

  build() {
    Stack() {
      if (this.selected) {
        Image($r("app.media.plvsa_preference_card_selected_icon"))
          .width(28)
          .height(32)
      }
      this.slot()
    }
    .alignContent(Alignment.BottomEnd)
    .borderWidth(1)
    .borderColor(this.selected ? '#4399FF' : 'transparent')
    .borderRadius(8)
    .backgroundColor('#0AF0F1F5')
  }

  @Builder
  noopSlot() {

  }
}