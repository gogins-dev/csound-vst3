/*
  ==============================================================================

    This file contains the basic framework code for a JUCE plugin editor.

  ==============================================================================
*/

#pragma once

#include "BinaryData.h"
#include <juce_audio_processors/juce_audio_processors.h>
#include <juce_audio_utils/juce_audio_utils.h>
#include <juce_gui_extra/juce_gui_extra.h>
#include "PluginProcessor.h"
#include "CsoundTokeniser.h"
#include "csoundvst3_version.h"

class SearchAndReplaceDialog : public juce::Component,
                               private juce::Button::Listener
{
public:
    SearchAndReplaceDialog(juce::CodeEditorComponent& editor)
        : codeEditor(editor)
    {
        addAndMakeVisible(searchLabel);
        searchLabel.setText("Search:", juce::dontSendNotification);

        addAndMakeVisible(searchField);

        addAndMakeVisible(replaceLabel);
        replaceLabel.setText("Replace:", juce::dontSendNotification);

        addAndMakeVisible(replaceField);

        addAndMakeVisible(searchButton);
        searchButton.setButtonText("Search");
        searchButton.addListener(this);

        addAndMakeVisible(replaceButton);
        replaceButton.setButtonText("Replace");
        replaceButton.addListener(this);

        setSize(400, 150);
    }

    void resized() override
    {
        auto bounds = getLocalBounds().reduced(10);
        auto row = bounds.removeFromTop(40);
        int margin = 8;

        searchLabel.setBounds(row.removeFromLeft(70));
        searchField.setBounds(row.reduced(margin));

        row = bounds.removeFromTop(40);
        replaceLabel.setBounds(row.removeFromLeft(70));
        replaceField.setBounds(row.reduced(margin));

        row = bounds.removeFromTop(40);
        replaceButton.setBounds(row.removeFromRight(120).reduced(margin));
        searchButton.setBounds(row.removeFromRight(120).reduced(margin));
     }

private:
    juce::CodeEditorComponent& codeEditor;

    juce::Label searchLabel, replaceLabel;
    juce::TextEditor searchField, replaceField;
    juce::TextButton searchButton, replaceButton;

    void buttonClicked(juce::Button* button) override
    {
        auto& document = codeEditor.getDocument();
        auto searchText = searchField.getText();

        if (button == &searchButton)
        {
            auto start = codeEditor.getHighlightedRegion().getEnd(); // Start after current selection
            auto content = document.getAllContent();
            auto foundPos = content.indexOf(start, searchText);

            if (foundPos != -1)
            {
                codeEditor.setHighlightedRegion({ foundPos, foundPos + searchText.length() });
            }
            else
            {
                juce::AlertWindow::showMessageBoxAsync(juce::AlertWindow::InfoIcon,
                                                  "Search", "Text not found.");
            }
        }
        else if (button == &replaceButton)
        {
            auto replaceText = replaceField.getText();
            auto start = codeEditor.getHighlightedRegion().getEnd();
            auto content = document.getAllContent();
            auto foundPos = content.indexOf(start, searchText);

            if (foundPos != -1)
            {
                document.deleteSection(foundPos, foundPos + searchText.length());
                document.insertText(foundPos, replaceText);
                codeEditor.setHighlightedRegion({ foundPos, foundPos + replaceText.length() });
            }
            else
            {
                juce::AlertWindow::showMessageBoxAsync(juce::AlertWindow::InfoIcon,
                                                  "Replace", "Text not found.");
            }
        }
    }
};

class CsoundVST3AudioProcessorEditor  : public juce::AudioProcessorEditor,
public juce::Button::Listener,
public juce::ChangeListener,
public juce::Timer
// public juce::TooltipWindow
{
    public:
    CsoundVST3AudioProcessorEditor (CsoundVST3AudioProcessor&);
    ~CsoundVST3AudioProcessorEditor() override;
    
    //==============================================================================
    void paint (juce::Graphics&) override;
    void resized() override;
    void changeListenerCallback(juce::ChangeBroadcaster*) override;
    void timerCallback() override;
    private:
    CsoundVST3AudioProcessor& audioProcessor;
    juce::CodeDocument csd_document;
    juce::CodeDocument messages_document;
    
    juce::TextButton openButton{"Open..."};
    juce::TextButton saveButton{"Save"};
    juce::TextButton saveAsButton{"Save as..."};
    juce::TextButton playButton{"Play"};
    juce::TextButton stopButton{"Stop"};
    juce::TextButton findButton{"Find..."};
    juce::TextButton aboutButton{"About"};
    
    juce::Label statusBar;
    juce::StretchableLayoutManager verticalLayout;
    juce::StretchableLayoutResizerBar divider;
    
    public:
    std::unique_ptr<CsoundTokeniser> csd_code_tokeniser;
    std::unique_ptr<juce::CodeEditorComponent> codeEditor;
    std::unique_ptr<juce::CodeEditorComponent> messageLog;

private:
    void buttonClicked(juce::Button* button) override;
    juce::TooltipWindow tooltipWindow { this }; // Enable tooltips
    std::unique_ptr<juce::FileChooser> fileChooser;
    juce::File csd_file;
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (CsoundVST3AudioProcessorEditor)
};
