/*
    csound_threaded.hpp:

    Copyright (C) 2017 Michael Gogins

    This file is part of Csound.

    The Csound Library is free software; you can redistribute it
    and/or modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    Csound is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with Csound; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
    02110-1301 USA

    As a special exception, if other files instantiate templates or
    use macros or inline functions from this file, this file does not
    by itself cause the resulting executable or library to be covered
    by the GNU Lesser General Public License. This exception does not
    however invalidate any other reasons why the library or executable
    file might be covered by the GNU Lesser General Public License.
*/

#pragma once

#if defined(__GNUC__)
#if __cplusplus <= 199711L
  #error To use csound_threaded.hpp you need at least a C++11 compliant compiler.
#endif
#endif

#ifdef SWIG
%module csnd6
%{
#include "csound.hpp"
%}
#endif
#include "csound.hpp"
#include <atomic>
#include <condition_variable>
#include <iomanip>
#include <memory>
#include <mutex>
#include <queue>
#include <sstream>
#include <string>
#include <thread>
#include <vector>

/**
 * A thread-safe queue, or first-in first-out (FIFO) queue, implemented using
 * only the standard C++11 library. The Data should be a simple type, such as
 * a pointer.
 */
template<typename Data>
class concurrent_queue
{
private:
    std::queue<Data> queue_;
    std::mutex mutex_;
    std::condition_variable condition_variable_;
public:
    void push(Data const& data)
    {
        std::unique_lock<std::mutex> lock(mutex_);
        queue_.push(data);
        lock.unlock();
        condition_variable_.notify_one();
    }
    bool empty()
    {
        std::unique_lock<std::mutex> lock(mutex_);
        return queue_.empty();
    }
    bool try_pop(Data& popped_value)
    {
        std::unique_lock<std::mutex> lock(mutex_);
        if (queue_.empty()) {
            return false;
        }
        popped_value = queue_.front();
        queue_.pop();
        return true;
    }
    void wait_and_pop(Data& popped_value)
    {
        std::unique_lock<std::mutex> lock(mutex_);
        while (queue_.empty()) {
            condition_variable_.wait(lock);
        }
        popped_value = queue_.front();
        queue_.pop();
    }
};

inline std::string csound_threaded_format_score_event(char opcode, const MYFLT *pfields, long pfield_count)
{
    std::ostringstream stream;
    stream << opcode;
    stream << std::setprecision(17);
    for (long i = 0; i < pfield_count; ++i) {
        stream << ' ' << pfields[i];
    }
    return stream.str();
}

/**
 * Abstract base class for Csound events to be enqueued
 * for performance.
 */
struct CsoundEvent
{
    virtual ~CsoundEvent() {};
    /**
     * Dispatches the event to Csound during performance.
     */
    virtual int operator ()(CSOUND *csound_) = 0;
};

/**
 * Specialization of CsoundEvent for low-level
 * score events with raw pfields.
 */
struct CsoundScoreEvent : public CsoundEvent
{
    char opcode;
    std::vector<MYFLT> pfields;
    CsoundScoreEvent(char opcode_, const MYFLT *pfields_, long pfield_count)
    {
        opcode = opcode_;
        for (long i = 0; i < pfield_count; i++) {
            pfields.push_back(pfields_[i]);
        }
    }
    virtual int operator ()(CSOUND *csound_)
    {
#if CSOUND_VERSION_MAJOR >= 7
        const std::string text = csound_threaded_format_score_event(opcode, pfields.data(), static_cast<long>(pfields.size()));
        csoundEventString(csound_, text.c_str(), 0);
        return 0;
#else
        return csoundScoreEvent(csound_, opcode, pfields.data(), static_cast<long>(pfields.size()));
#endif
    }
};

/**
 * Specialization of CsoundEvent for high-level textual score
 * events, fragments of scores, or entire scores.
 */
struct CsoundTextEvent : public CsoundEvent
{
    std::string events;
    CsoundTextEvent(const char *text)
    {
        events = text;
    }
    virtual int operator ()(CSOUND *csound_)
    {
#if CSOUND_VERSION_MAJOR >= 7
        csoundEventString(csound_, events.c_str(), 0);
        return 0;
#else
        return csoundReadScore(csound_, events.c_str());
#endif
    }
};

/**
 * This class provides a multi-threaded C++ interface to the "C" Csound API.
 * The interface is identical to the C++ interface of the Csound class in
 * csound.hpp; however, the ::Perform() function runs in a separate thread of
 * execution that is fed by a thread-safe FIFO of messages from ::ScoreEvent,
 * ::InputMessage, and ::ReadScore.
 *
 * This is a header-file-only facility. The multi-threaded features of this
 * class are minimalistic, but seem sufficient for most purposes. There are
 * no external dependences apart from Csound and the standard C++ library.
 */
class PUBLIC CsoundThreaded : public Csound
{
protected:
    std::thread performance_thread;
    void (*kperiod_callback)(CSOUND *, void *);
    void *kperiod_callback_user_data;
    concurrent_queue<CsoundEvent *> input_queue;
    std::string output_type;
    std::string output_format;      
    std::string output_name;

    void ClearQueue()
    {
        CsoundEvent *event = 0;
        while (input_queue.try_pop(event)) {
            delete event;
        }
    }

#if CSOUND_VERSION_MAJOR >= 7
    int ReadScoreNow(const char *score)
    {
        csoundEventString(csound, score, 0);
        return 0;
    }

    int ScoreEventNow(char opcode, const MYFLT *pfields, long pfield_count)
    {
        const std::string text = csound_threaded_format_score_event(opcode, pfields, pfield_count);
        csoundEventString(csound, text.c_str(), 0);
        return 0;
    }
#endif

public:
    std::atomic<bool> keep_running;

    CsoundThreaded()
        : Csound()
        , kperiod_callback(nullptr)
        , kperiod_callback_user_data(nullptr)
        , keep_running(false)
    {
    }

    CsoundThreaded(CSOUND *csound_)
        : Csound(csound_)
        , kperiod_callback(nullptr)
        , kperiod_callback_user_data(nullptr)
        , keep_running(false)
    {
    }

    CsoundThreaded(void *host_data)
        : Csound(host_data)
        , kperiod_callback(nullptr)
        , kperiod_callback_user_data(nullptr)
        , keep_running(false)
    {
    }

    virtual ~CsoundThreaded()
    {
        Stop();
        Join();
        ClearQueue();
    }

#if defined(CSOUND_VERSION_MAJOR) && CSOUND_VERSION_MAJOR >= 7
    /**
     * Compatibility wrappers for methods that existed in the Csound 6 C++
     * wrapper but were removed from the Csound 7 C++ wrapper.
     */
    virtual int32_t CompileCsd(const char *csd_filename)
    {
        return csoundCompileCSD(csound, csd_filename, 0, 0);
    }

    virtual int32_t CompileCsdText(const char *csd_text)
    {
        return csoundCompileCSD(csound, csd_text, 1, 0);
    }

    virtual int32_t GetNchnls()
    {
        return GetChannels(0);
    }

    virtual int32_t GetNchnlsInput()
    {
        return GetChannels(1);
    }

    virtual int32_t Cleanup()
    {
        return 0;
    }

    virtual int32_t ReadScoreImmediate(const char *score)
    {
        return ReadScoreNow(score);
    }

    virtual int32_t ScoreEventImmediate(char opcode, const MYFLT *pfields, long pfield_count)
    {
        return ScoreEventNow(opcode, pfields, pfield_count);
    }


    virtual int SetInput(const char *input)
    {
        std::string option = "--input=";
        option += input;
        return SetOption(option.c_str());
    }

#endif



    /**
     * Compatibility wrappers for Csound 6 C++ wrapper methods that are
     * absent from the Csound 7 C++ wrapper. Keep these in CsoundThreaded
     * so embind and other clients can call one stable C++ API.
     */
    virtual void SetHostImplementedAudioIO(int state)
    {
#if defined(CSOUND_VERSION_MAJOR) && CSOUND_VERSION_MAJOR >= 7
        // Csound 7 removed csoundSetHostImplementedAudioIO(CSOUND *, int, int)
        // and replaced it with one-way host audio I/O selection. There is no
        // C API call to disable host audio I/O again, so state == 0 is a no-op.
        if (state != 0)
        {
            csoundSetHostAudioIO(csound);
        }
#else
        Csound::SetHostImplementedAudioIO(state);
#endif
    }

    virtual void SetHostImplementedMIDIIO(int state)
    {
#if defined(CSOUND_VERSION_MAJOR) && CSOUND_VERSION_MAJOR >= 7
        // Csound 7 removed csoundSetHostImplementedMIDIIO(CSOUND *, int)
        // and replaced it with one-way host MIDI I/O selection. There is no
        // C API call to disable host MIDI I/O again, so state == 0 is a no-op.
        if (state != 0)
        {
            csoundSetHostMIDIIO(csound);
        }
#else
        Csound::SetHostImplementedMIDIIO(state);
#endif
    }

    virtual void SetExternalMidiInOpenCallback(int (*callback)(CSOUND *, void **, const char *))
    {
#if defined(CSOUND_VERSION_MAJOR) && CSOUND_VERSION_MAJOR >= 7
        csoundSetExternalMidiInOpenCallback(csound, callback);
#else
        Csound::SetExternalMidiInOpenCallback(callback);
#endif
    }

    virtual void SetExternalMidiReadCallback(int (*callback)(CSOUND *, void *, unsigned char *, int))
    {
#if defined(CSOUND_VERSION_MAJOR) && CSOUND_VERSION_MAJOR >= 7
        csoundSetExternalMidiReadCallback(csound, callback);
#else
        Csound::SetExternalMidiReadCallback(callback);
#endif
    }

    virtual void SetExternalMidiInCloseCallback(int (*callback)(CSOUND *, void *))
    {
#if defined(CSOUND_VERSION_MAJOR) && CSOUND_VERSION_MAJOR >= 7
        csoundSetExternalMidiInCloseCallback(csound, callback);
#else
        Csound::SetExternalMidiInCloseCallback(callback);
#endif
    }

    virtual MYFLT TableGet(int table, int index)
    {
#if defined(CSOUND_VERSION_MAJOR) && CSOUND_VERSION_MAJOR >= 7
        // Csound 7 removed csoundTableGet(). Use csoundGetTable() and
        // index directly into the returned table memory.
        MYFLT *table_data = nullptr;
        int table_length = csoundGetTable(csound, &table_data, table);
        if (table_data == nullptr || index < 0 || index >= table_length)
        {
            return static_cast<MYFLT>(0);
        }
        return table_data[index];
#else
        return Csound::TableGet(table, index);
#endif
    }

    virtual void TableSet(int table, int index, MYFLT value)
    {
#if defined(CSOUND_VERSION_MAJOR) && CSOUND_VERSION_MAJOR >= 7
        // Csound 7 removed csoundTableSet(). Use csoundGetTable() and
        // write directly into the returned table memory.
        MYFLT *table_data = nullptr;
        int table_length = csoundGetTable(csound, &table_data, table);
        if (table_data == nullptr || index < 0 || index >= table_length)
        {
            return;
        }
        table_data[index] = value;
#else
        Csound::TableSet(table, index, value);
#endif
    }

    virtual int SetOutput(const char *name, const char *type, const char *format)
    {
#if defined(CSOUND_VERSION_MAJOR) && CSOUND_VERSION_MAJOR  >= 7
        int result = 0;
        output_name = name;
        output_type = type;
        output_format = format;
        if (name != nullptr && name[0] != '\0')
        {
            std::string option = "--output=";
            option += name;
            result = SetOption(option.c_str());
            if (result != 0)
            {
                return result;
            }
        }
        if ((type != nullptr && type[0] != '\0') ||
            (format != nullptr && format[0] != '\0'))
        {
            std::string option = "--format=";

            if (type != nullptr && type[0] != '\0' &&
                format != nullptr && format[0] != '\0')
            {
                option += type;
                option += ":";
                option += format;
            }
            else if (type != nullptr && type[0] != '\0')
            {
                option += type;
            }
            else
            {
                option += format;
            }

            result = SetOption(option.c_str());
            if (result != 0)
            {
                return result;
            }
        }
        std::fprintf(stderr, "CsoundThreaded::SetOutput: name:  %s type: %s format: %s...\n", name, type, format);
        return 0;
#else
        csoundSetOutput(csound, name, type, format);
        return 0;
#endif
    }

    virtual void SetKperiodCallback(void (*kperiod_callback_)(CSOUND *, void *), void *kperiod_callback_user_data_)
    {
        kperiod_callback = kperiod_callback_;
        kperiod_callback_user_data = kperiod_callback_user_data_;
    }

    virtual int PerformRoutine()
    {
        Message("Began CsoundThreaded::PerformRoutine()...\n");
        keep_running = true;
        int result = 0;
        while (true) {
            if (keep_running == false) {
                break;
            }
            CsoundEvent *event = 0;
            while (input_queue.try_pop(event)) {
                (*event)(csound);
                delete event;
            }
            if (kperiod_callback != nullptr) {
                kperiod_callback(csound, kperiod_callback_user_data);
            }
            result = Csound::PerformKsmps();
            if (result != 0) {
                Message("CsoundThreaded::PerformRoutine(): CsoundThreaded::PerformKsmps() ended with %d...\n", result);
                break;
            }
        }
        keep_running = false;
        ClearQueue();
        Message("CsoundThreaded::PerformRoutine(): Cleared performance queue...\n");
        Message("Ended CsoundThreaded::PerformRoutine() with %d.\n", result);
        return result;
    }

    virtual int PerformAndResetRoutine()
    {
        Message("Began CsoundThreaded::PerformAndResetRoutine()...\n");
        keep_running = true;
        int result = 0;
        while (true) {
            if (keep_running == false) {
                break;
            }
            CsoundEvent *event = 0;
            while (input_queue.try_pop(event)) {
                (*event)(csound);
                delete event;
            }
            if (kperiod_callback != nullptr) {
                kperiod_callback(csound, kperiod_callback_user_data);
            }
            result = Csound::PerformKsmps();
            if (result != 0) {
                Message("CsoundThreaded::PerformAndResetRoutine(): CsoundThreaded::PerformKsmps() ended with %d...\n", result);
                break;
            }
        }
        keep_running = false;
        ClearQueue();
        Message("CsoundThreaded::PerformAndResetRoutine(): Cleared performance queue...\n");
        result = Cleanup();
        Message("CsoundThreaded::PerformAndResetRoutine(): Cleanup() returned %d...\n", result);
        Reset();
        Message("CsoundThreaded::PerformAndResetRoutine(): Reset() returned...\n");
        Message("Ended CsoundThreaded::PerformAndResetRoutine() with %d.\n", result);
        return result;
    }

    /**
     * Overrides Csound::Perform to run in a separate thread of execution.
     * The granularity of time is one kperiod. If a kperiod callback has been
     * set, it is called with the CSOUND object and any user data on every
     * kperiod.
     */
    virtual int Perform()
    {
        performance_thread = std::thread(&CsoundThreaded::PerformRoutine, this);
        return 0;
    }

    /**
     * Like Perform, but calls Cleanup() and Reset() at the conclusion of the
     * performance, so that this is done in the performance thread.
     */
    virtual int PerformAndReset()
    {
        performance_thread = std::thread(&CsoundThreaded::PerformAndResetRoutine, this);
        return 0;
    }

    /**
     * Enqueues a low-level score event with raw pfields for dispatch from
     * the performance thread routine.
     */
    virtual int ScoreEvent(char opcode, const MYFLT *pfields, long pfield_count)
    {
        int result = 0;
        CsoundScoreEvent *event = new CsoundScoreEvent(opcode, pfields, pfield_count);
        input_queue.push(event);
        return result;
    }

    /**
     * Enqueues a textual score event or events for dispatch from the
     * performance thread routine.
     */
    virtual void InputMessage(const char *message)
    {
        CsoundTextEvent *event = new CsoundTextEvent(message);
        input_queue.push(event);
    }

    /**
     * Enqueues a textual score event, score fragment, or entire score for
     * dispatch from the performance thread routine.
     */
    virtual int ReadScore(const char *score)
    {
        int result = 0;
        CsoundTextEvent *event = new CsoundTextEvent(score);
        input_queue.push(event);
        return result;
    }

    /**
     * Signals the performance thread routine to stop and return.
     */
    virtual void Stop()
    {
        Message("CsoundThreaded::Stop()...\n");
        keep_running = false;
#if CSOUND_VERSION_MAJOR < 7
        Csound::Stop();
#else
        SetScorePending(0);
#endif
        Message("CsoundThreaded::Stop().\n");
    }

    /**
     * Causes the calling thread to wait for the end of the performance
     * thread routine.
     */
    virtual void Join()
    {
        Message("CsoundThreaded::Join()...\n");
        if (performance_thread.joinable()) {
            performance_thread.join();
        }
        Message("CsoundThreaded::Join().\n");
    }

    /**
     * Returns whether or not the performance thread routine is running.
     */
    virtual bool IsPlaying() const
    {
       return keep_running;
    }
};
